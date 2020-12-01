# PRESENTATION

module "public_network" {
  source            = "../public_network"
  vpc_id            = var.vpc_id
  subnet_cidr_block = ["10.0.0.0/28", "10.0.0.16/28"]
  availability_zone = ["eu-west-2a", "eu-west-2b"]
}

module "load_balancer" {
  source              = "../load_balancer"
  vpc_id              = var.vpc_id
  port                = 80
  sg_ingress_protocol = "tcp"
  alb_name            = "alb"
  alb_subnet_ids      = module.public_network.subnet_ids
  tg_name             = "target-group"
  tg_protocol         = "HTTP"
  tg_hc_path          = "/"
  l_protocol          = "HTTP"
  l_da_type           = "forward"
}

module "autoscaling_group" {
  source                = "../autoscaling_group"
  ssh_key               = var.ssh_key
  ami                   = "ami-053b5dc3907b8bd31"
  instance_type         = "t2.micro"
  user_data             = var.user_data
  public_ip             = false
  delete_on_termination = true
  sg_id                 = [module.load_balancer.sg_id]
  max_size              = 4
  min_size              = 1
  hc_grace_period       = 300
  hc_check_type         = "ELB"
  desired_capacity      = 2
  force_delete          = true
  subnets               = module.public_network.subnet_ids
  tg_arn                = [module.load_balancer.alb_tg_arn]
}