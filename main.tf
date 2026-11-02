resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public-route-table-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = var.ssh_public_key
}

resource "aws_instance" "bastion-host" {
  ami                         = "ami-0567589d25e06853e"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnet.id
  key_name                    = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow traffic from bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}
# 3. Private Route Table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# 4. Associate Private Subnet with Route Table
resource "aws_route_table_association" "private-association" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-route-table.id
}

resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-subnet.id

  depends_on = [aws_internet_gateway.my-igw]

  tags = {
    Name = "my-nat-gateway"
  }
}

resource "aws_instance" "private-instance" {
  ami                         = "ami-0567589d25e06853e"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  associate_public_ip_address = false
  subnet_id                   = aws_subnet.private-subnet.id
  key_name                    = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "private-instance"
  }
}




resource "null_resource" "deploy_python" {

  triggers = {
    app_hash    = filesha256("${path.module}/app/app.py")
    req_hash    = filesha256("${path.module}/app/requirements.txt")
    script_hash = filesha256("${path.module}/app/install.sh")
    instance_id = aws_instance.private-instance.id
  }

  connection {
    type = "ssh"

    host = aws_instance.private-instance.private_ip
    user = "ec2-user"

    bastion_host = aws_instance.bastion-host.public_ip
    bastion_user = "ec2-user"

    private_key         = var.ssh_private_key
    bastion_private_key = var.ssh_private_key

    timeout = "5m"
  }

  # Copy Python application
  provisioner "file" {
    source      = "${path.module}/app/app.py"
    destination = "/tmp/app.py"
  }

  # Copy dependencies
  provisioner "file" {
    source      = "${path.module}/app/requirements.txt"
    destination = "/tmp/requirements.txt"
  }

  # Copy installation script
  provisioner "file" {
    source      = "${path.module}/app/install.sh"
    destination = "/tmp/install.sh"
  }

  # Execute script on private EC2
  provisioner "remote-exec" {
    inline = [
      "bash /tmp/install.sh"
    ]
  }
}


# Add load balancer for the private instance
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public-route-table.id
}


resource "aws_security_group" "alb_sg" {
  name   = "fastapi-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}


resource "aws_lb" "fastapi_alb" {
  name               = "fastapi-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public-subnet.id,
    aws_subnet.public_subnet_2.id
  ]
}


resource "aws_lb_target_group" "fastapi_tg" {
  name        = "fastapi-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "instance"

  health_check {
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_target_group_attachment" "fastapi_target" {
  target_group_arn = aws_lb_target_group.fastapi_tg.arn
  target_id        = aws_instance.private-instance.id
  port             = 8000
}


resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.fastapi_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fastapi_tg.arn
  }
}
