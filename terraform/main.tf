provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "paras-vpc" {
 cidr_block = "10.0.0.0/16"
  tags = {
   Name = "paras-vpc"
}
}

resource "aws_subnet" "subnet-1"{

vpc_id = aws_vpc.paras-vpc.id
cidr_block = "10.0.1.0/24"
depends_on = [aws_vpc.paras-vpc]
map_public_ip_on_launch = true
  tags = {
   Name = "paras-subnet"
}
}

resource "aws_route_table" "paras-route-table"{
vpc_id = aws_vpc.paras-vpc.id
  tags = {
   Name = "paras-route-table"
}
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.paras-route-table.id
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.paras-vpc.id
 depends_on = [aws_vpc.paras-vpc]
   tags = {
   Name = "paras-gw"
}
}

resource "aws_route" "paras-route" {

route_table_id = aws_route_table.paras-route-table.id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
}

variable "sg_ports" {
type = list(number)
default = [8080,80,22,443]
}
resource "aws_security_group" "paras-sg" {
  name        = "sg_rule"
  vpc_id = aws_vpc.paras-vpc.id
  dynamic  "ingress" {
    for_each = var.sg_ports
    iterator = port
    content{
    from_port        = port.value
    to_port          = port.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  }
egress {

    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

}
}

resource "aws_instance" "myec2" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.medium"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-main"
  }

}

resource "aws_instance" "myec2-test" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.micro"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-test"
  }

}

resource "aws_instance" "myec2-prod" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.micro"
  key_name = "project-bnf"
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.paras-sg.id]
  tags = {
    Name = "Project-Dev-prod"
  }

}
