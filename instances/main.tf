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

module "load-balancer" {
  source              = "./modules/load-balancer"
  sg-vpc-id           = module.network.vpc-id
  port                = 80
  sg-ingress-protocol = "tcp"
  alb-name            = "my-alb"
  alb-subnet-ids      = module.network.subnet-ids
  tg-name             = "my-alb-target-group"
  tg-protocol         = "HTTP"
  tg-vpc-id           = module.network.vpc-id
  tg-hc-path          = "/"
  l-protocol          = "HTTP"
  l-da-type           = "forward"
}

module "autoscaling-group" {
  source                = "./modules/autoscaling-group"
  ssh-key               = var.ssh_key
  ami                   = "ami-053b5dc3907b8bd31"
  instance-type         = "t2.micro"
  user-data             = data.template_file.user_data.rendered
  public-ip             = false
  delete-on-termination = true
  sg-id                 = [module.load-balancer.sg-id]
  max-size              = 4
  min-size              = 1
  hc-grace-period       = 300
  hc-check-type         = "ELB"
  desired-capacity      = 2
  force-delete          = true
  subnets               = module.network.subnet-ids
  tg-arn                = [module.load-balancer.alb-tg-arn]
}
