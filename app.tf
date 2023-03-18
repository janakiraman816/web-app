# data "aws_vpc" "main-vpc" {
#   id = "vpc-0762d741e0f27c7a7"
# }

resource "aws_security_group" "load-balancer-sg" {
  name = "load-balancer-sg"
  ingress{
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "allow http traffic from anywhere"
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    
  } 
}

resource "aws_security_group" "web-app-sg" {
  name = "web-app-security-group"
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.load-balancer-sg.id]
    description = "allow http traffic from load balancer"
  }

  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "allow ssh on port 22"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

resource "aws_launch_template" "web-app-launch-template" {
  name = "web-app-launch-template"
  image_id = "ami-05afd67c4a44cc983"
  instance_type = "t2.micro"
  key_name = "EC2Key_Mumbai_Region"
  vpc_security_group_ids = [aws_security_group.web-app-sg.id]
  user_data = base64encode(file("./userscript.sh"))
}

resource "aws_autoscaling_group" "web-app-asg" {
  name = "web-app-asg"
  desired_capacity = 2
  min_size = 2
  max_size = 3
  availability_zones = [ "ap-south-1a", "ap-south-1b" ]
  health_check_grace_period = 90
  

  launch_template {
    id = aws_launch_template.web-app-launch-template.id
    version = "$Latest"
  }
}

