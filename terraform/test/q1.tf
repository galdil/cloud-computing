# question 1.a
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
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

resource "aws_elb" "elb-hw1" {
  name               = "elb-hw1"
  availability_zones = ["${aws_instance.first.availability_zone}", "${aws_instance.second.availability_zone}"]
  security_groups    = ["${aws_security_group.webservers.id}"]

  listener {
    instance_port     = 22
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:22/"
    interval            = 30
  }

  instances                   = ["${aws_instance.first.id}", "${aws_instance.second.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300
}

# question 1.b
resource "aws_db_instance" "db-hw1" {
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

# question 1.c
# resource "aws_launch_configuration" "launch-config" {
#   image_id        = "ami-2757f631"
#   instance_type   = "t2.micro"
#   security_groups = ["${aws_security_group.webservers.id}"]

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_autoscaling_group" "asg-hw1" {
#   launch_configuration = "${aws_launch_configuration.launch-config.name}"
#   availability_zones = ["${data.aws_availability_zone.available.name}"]

#   target_group_arns = ["${var.target_group_arn}"]
#   health_check_type = "EC2"

#   min_size = 2
#   max_size = 4

#   tag {
#     key                 = "Name"
#     value               = "my-asg"
#     propagate_at_launch = true
#   }
# }
