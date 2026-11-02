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
    cidr_blocks = ["10.0.0.0/0"]
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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