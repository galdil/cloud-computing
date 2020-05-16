provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_us_east_1a" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_us_east_1b" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_security_group" "webservers" {
  name        = "hw1_sg"
  description = "hw1 security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["188.64.207.129/32"]
    description = "lb port"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["188.64.207.129/32"]
    description = "db port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "first" {
  ami               = "ami-2757f631"
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]
  security_groups   = ["${aws_security_group.webservers.name}"]

  tags = {
    Name = "Server0"
  }
}

resource "aws_instance" "second" {
  ami               = "ami-2757f631"
  instance_type     = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[1]
  security_groups   = ["${aws_security_group.webservers.name}"]

  tags = {
    Name = "Server1"
  }
}

resource "aws_lb" "hw1" {
  name               = "hw1-terraform-alb"
  security_groups    = ["${aws_security_group.webservers.id}"]
  load_balancer_type = "application"
  subnets            = ["${aws_subnet.public_us_east_1a.id}", "${aws_subnet.public_us_east_1b.id}"]

  tags = {
    Name = "hw1-terraform-alb"
  }
}

resource "aws_lb_target_group_attachment" "tg-first-attachment" {
  target_group_arn = "${aws_lb_target_group.lb-target.arn}"
  target_id        = "${aws_instance.first.id}"
  port             = 22
}

resource "aws_lb_target_group_attachment" "tg-second-attachment" {
  target_group_arn = "${aws_lb_target_group.lb-target.arn}"
  target_id        = "${aws_instance.second.id}"
  port             = 22
}

resource "aws_lb_target_group" "lb-target" {
  name     = "hw1-lb-target-group"
  port     = 22
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.my_vpc.id}"
}

resource "aws_db_instance" "hw1" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "gal"
  password               = "galdil323"
  skip_final_snapshot    = "true"
  vpc_security_group_ids = ["${aws_security_group.webservers.id}"]
}
