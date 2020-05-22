provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# I have created a vpc and subnets in different availabilty zones.
# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

# Subnets
resource "aws_subnet" "main-private-1" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "main-private-1"
  }
}

resource "aws_subnet" "main-private-2" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "main-private-1"
  }
}

# Internet GW
resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

# creating security group for the instances
resource "aws_security_group" "webservers" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "webservers"
  description = "hw1 security group"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["188.64.207.129/32"]
    description = "lb port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webservers"
  }
}

# ELB
# I choose to create LB of type classic ELB.
# As far as we don't really know what is the type of application/service we want for our project
# We can use the simplest type we can configure.
# If we would know that the project is application based we will use ALB which is better for HTTP/S traffic
# If we are working with TCP/UDP traffic we would choose the NLB.
resource "aws_elb" "elb-hw1" {
  name            = "elb-hw1"
  security_groups = ["${aws_security_group.elb-sg.id}"]
  subnets         = ["${aws_subnet.main-private-1.id}", "${aws_subnet.main-private-2.id}"]

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

  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "elb-hw1"
  }
}

# SG for the LB
# Can access the LB through port 80
resource "aws_security_group" "elb-sg" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "elb-sg"
  description = "hw1 security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["188.64.207.129/32"]
    description = "lb port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elb-sg"
  }
}

# RDB
# I choose postgres RDS, the instances can access it on port 5432
resource "aws_db_subnet_group" "postgres-subnet" {
  name        = "postgres-subnet"
  description = "RDS subnet group"
  subnet_ids  = ["${aws_subnet.main-private-1.id}", "${aws_subnet.main-private-2.id}"]
}

resource "aws_db_instance" "db-hw1" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t2.micro"
  name                   = "mydb"
  username               = "root"
  password               = "galdil323"
  skip_final_snapshot    = "true"
  db_subnet_group_name   = "${aws_db_subnet_group.postgres-subnet.name}"
  vpc_security_group_ids = ["${aws_security_group.allow-db.id}"]
  availability_zone      = "${aws_subnet.main-private-1.availability_zone}"

  tags = {
    Name = "db-hw1"
  }
}

# The RDS SG uses the instances's SG, thus only the instances have access to it.
resource "aws_security_group" "allow-db" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "allow-db"
  description = "db security group"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.webservers.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webservers"
  }
}

# Autoscaling
# The auto scaling creates 2 instances in different AS and check for CPU threshold
# In that way we will always have 2 instances
resource "aws_launch_configuration" "launch-config" {
  name            = "launch-config"
  image_id        = "ami-2757f631"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.webservers.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg-hw1" {
  name_prefix          = "asg-hw1"
  launch_configuration = "${aws_launch_configuration.launch-config.name}"
  vpc_zone_identifier  = ["${aws_subnet.main-private-1.id}", "${aws_subnet.main-private-2.id}"]
  health_check_type    = "EC2"
  load_balancers       = ["${aws_elb.elb-hw1.name}"]
  min_size             = 2
  max_size             = 2

  tag {
    key                 = "Name"
    value               = "instance-hw1"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.asg-hw1.id}"
  elb                    = "${aws_elb.elb-hw1.id}"
}

resource "aws_autoscaling_policy" "cpu-policy" {
  name                   = "cpu-policy"
  autoscaling_group_name = "${aws_autoscaling_group.asg-hw1.name}"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

## cloud watch alarm that will be fire if total CPU utilization of all instances in our
## Auto Scaling Group will be greater or equal threshold during 120 seconds. 
resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name          = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg-hw1.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions     = ["${aws_autoscaling_policy.cpu-policy.arn}"]
}
