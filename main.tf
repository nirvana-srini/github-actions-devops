resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
    tags = {
        Name = "main-vpc"
    }
}

resource "aws_instance" "web" {
  ami           = "ami-0567589d25e06853e"
  instance_type = "t2.micro"
  tags = {
    Name = "web-instance"
  }
}