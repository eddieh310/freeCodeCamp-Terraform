terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# hard coding everything.... for now

provider "aws" {
  region = "us-east-1"
}
/*
resource "aws_instance" "codeCampEc2" {
  ami = "ami-0e449927258d45bc4"
  instance_type = "t2.micro"
  tags = {
    Name = "FreeCodeCamp"
  }
}
*/


# note, fcc = free code camp, the tutorial followed is here: https://www.youtube.com/watch?v=SLB_c_ayRMo

resource "aws_vpc" "fccVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name      = "FreeCodeCampVPC"
    createdBy = "Terraform"
  }
}

resource "aws_internet_gateway" "fccIGW" {
  vpc_id = aws_vpc.fccVPC.id
}

resource "aws_route_table" "fccIGW_RT" {
  vpc_id = aws_vpc.fccVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fccIGW.id
  }


  tags = {
    Name      = "fcc-Internet-Gateway"
    createdBy = "Terraform"
  }
}

resource "aws_subnet" "fccSubnet" {
  vpc_id            = aws_vpc.fccVPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name      = "public-subnet-fcc"
    createdBy = "Terraform"
  }
}

resource "aws_route_table_association" "fccRouteTableAssos" {
  subnet_id      = aws_subnet.fccSubnet.id
  route_table_id = aws_route_table.fccIGW_RT.id
}

resource "aws_security_group" "allowWebFromMyIP" {
  name        = "allow-web-from-my-ip"
  description = "allow web traffic from my work laptops ip"
  vpc_id      = aws_vpc.fccVPC.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["24.188.68.192/32"] # li home ip pub
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["24.188.68.192/32"] # li home ip pub
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["24.188.68.192/32"] # li home ip pub
  }

  egress  {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fcc-SecurityGroup-allow-my-ip"
    createdBy = "Terraform"
  }
}

resource "aws_instance" "fccEC2" {
    ami = "ami-0e449927258d45bc4"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.allowWebFromMyIP.id ]
    subnet_id = aws_subnet.fccSubnet.id
    availability_zone = "us-east-1a"
    associate_public_ip_address = true
    key_name = "SSHIntoEC2"
    tags = {
        Name = "FreeCodeCamp"
        createdBy = "Terraform"
    }
}

