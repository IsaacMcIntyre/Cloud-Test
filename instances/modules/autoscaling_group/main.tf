resource "aws_key_pair" "deployer" {
  key_name = "deployer_key"
  public_key = var.ssh_key
}

resource "aws_launch_template" "launch_template" {
  image_id                      = var.ami #"ami_053b5dc3907b8bd31"
  instance_type                 = var.instance_type #"t2.micro"
  user_data                     = base64encode(var.user_data)#data.template_file.user_data.rendered)
  network_interfaces {
    associate_public_ip_address = var.public_ip #false
    delete_on_termination       = var.delete_on_termination #true
    security_groups             = var.sg_id #[module.load_balancer.sg_id]
  }
  key_name                      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                          = "autoscaling_group"
  max_size                      = var.max_size #4
  min_size                      = var.min_size #1
  health_check_grace_period     = var.hc_grace_period #300
  health_check_type             = var.hc_check_type #"ELB"
  desired_capacity              = var.desired_capacity #2
  force_delete                  = var.force_delete #true
  launch_template {
    id                          = aws_launch_template.launch_template.id
  }
  vpc_zone_identifier           = var.subnets #[aws_subnet.subnet_public.id, aws_subnet.subnet_public_2.id]
  target_group_arns             = var.tg_arn #[module.load_balancer.alb_tg_arn]
}