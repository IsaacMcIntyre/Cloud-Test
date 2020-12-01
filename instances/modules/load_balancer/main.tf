# LOAD BALANCER

resource "aws_security_group" "sg" {
  name        = "lb_security_group"
  description = "Load balancer security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.port
    to_port     = var.port
    protocol    = var.sg_ingress_protocol
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
  name            = var.alb_name 
  security_groups = [aws_security_group.sg.id]
  subnets         = var.alb_subnet_ids
}

resource "aws_alb_target_group" "group" {
  name     = var.tg_name
  port     = var.port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  stickiness {
    type = "lb_cookie"
  }

  health_check {
    path = var.tg_hc_path
    port = var.port
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = var.port
  protocol          = var.l_protocol

  default_action {
    target_group_arn = aws_alb_target_group.group.arn
    type             = var.l_da_type
  }
}
