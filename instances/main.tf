provider "aws" {
  region  = var.region
}

data "template_file" "user_data" {
  template          = file("../scripts/install-docker.yaml")

  vars = {
    ecr_account_id  = var.ecr_account_id
    ecr_image_name  = var.ecr_image_name
  }
}

module "network" {
  source                = "./modules/network"
  vpc_cidr_block        = "10.0.0.0/24"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  subnet_cidr_block     = ["10.0.0.0/28", "10.0.0.16/28"]
  availability_zone     = ["eu-west-2a", "eu-west-2b"]
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  sg_vpc_id           = module.network.vpc_id
  port                = 80
  sg_ingress_protocol = "tcp"
  alb_name            = "alb"
  alb_subnet_ids      = module.network.subnet_ids
  tg_name             = "target-group"
  tg_protocol         = "HTTP"
  tg_vpc_id           = module.network.vpc_id
  tg_hc_path          = "/"
  l_protocol          = "HTTP"
  l_da_type           = "forward"
}

module "autoscaling_group" {
  source                = "./modules/autoscaling_group"
  ssh_key               = var.ssh_key
  ami                   = "ami-053b5dc3907b8bd31"
  instance_type         = "t2.micro"
  user_data             = data.template_file.user_data.rendered
  public_ip             = false
  delete_on_termination = true
  sg_id                 = [module.load_balancer.sg_id]
  max_size              = 4
  min_size              = 1
  hc_grace_period       = 300
  hc_check_type         = "ELB"
  desired_capacity      = 2
  force_delete          = true
  subnets               = module.network.subnet_ids
  tg_arn                = [module.load_balancer.alb_tg_arn]
}
