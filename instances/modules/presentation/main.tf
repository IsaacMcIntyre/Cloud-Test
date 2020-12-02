# PRESENTATION

#public network
resource "aws_route_table" "rtb_public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }
}

module "subnet_1" {
  source = "../subnet"
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block[0]
  availability_zone = var.availability_zone[0]
  route_table_id = aws_route_table.rtb_public.id
}

module "subnet_2" {
  source = "../subnet"
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block[1]
  availability_zone = var.availability_zone[1]
  route_table_id = aws_route_table.rtb_public.id
}

# LB
resource "aws_security_group" "sg" {
  name        = "lb_security_group"
  description = "Load balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "alb" {
  name            = "alb" 
  security_groups = [aws_security_group.sg.id]
  subnets         = [module.subnet_1.subnet_id, module.subnet_2.subnet_id]
}

resource "aws_alb_target_group" "group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = "forward"
  }
}

# ASG
resource "aws_key_pair" "deployer" {
  key_name = "deployer_key"
  public_key = var.ssh_key
}

resource "aws_launch_template" "launch_template" {
  image_id                      = "ami-053b5dc3907b8bd31"
  instance_type                 = "t2.micro"
  user_data                     = base64encode(var.user_data)
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [aws_security_group.sg.id]
  }
  key_name                      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                          = "autoscaling_group"
  max_size                      = 4
  min_size                      = 1
  health_check_grace_period     = 300
  health_check_type             = "ELB"
  desired_capacity              = 2
  force_delete                  = true
  launch_template {
    id                          = aws_launch_template.launch_template.id
  }
  vpc_zone_identifier           = [module.subnet_1.subnet_id, module.subnet_2.subnet_id]
  target_group_arns             = [aws_alb_target_group.group.arn]
}
