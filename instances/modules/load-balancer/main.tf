resource "aws_security_group" "sg" {
  name        = "lb_security_group"
  description = "Load balancer security group"
  vpc_id      = var.sg-vpc-id #aws_vpc.vpc.id

  ingress {
    from_port   = var.port #80
    to_port     = var.port #80
    protocol    = var.sg-ingress-protocol #"tcp"
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
  name            = var.alb-name #"my-terraform-alb"
  security_groups = [aws_security_group.sg.id]
  subnets         = var.alb-subnet-ids #[aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id]
}

resource "aws_alb_target_group" "group" {
  name     = var.tg-name #"terraform-alb-target-group"
  port     = var.port #80
  protocol = var.tg-protocol #"HTTP"
  vpc_id   = var.tg-vpc-id #aws_vpc.vpc.id
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = var.tg-hc-path #"/"
    port = var.port #80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = var.port #"80"
  protocol          = var.l-protocol #"HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = var.l-da-type #"forward"
  }
}
