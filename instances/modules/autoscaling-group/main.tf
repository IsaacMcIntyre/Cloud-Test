resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key = var.ssh-key
}

resource "aws_launch_template" "launch_template" {
image_id                        = var.ami #"ami-053b5dc3907b8bd31"
  instance_type                 = var.instance-type #"t2.micro"
  user_data                     = base64encode(var.user-data)#data.template_file.user_data.rendered)
  network_interfaces {
    associate_public_ip_address = var.public-ip #false
    delete_on_termination       = var.delete-on-termination #true
    security_groups             = var.sg-id #[module.load-balancer.sg-id]
  }
  key_name                      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                          = "autoscaling_group"
  max_size                      = var.max-size #4
  min_size                      = var.min-size #1
  health_check_grace_period     = var.hc-grace-period #300
  health_check_type             = var.hc-check-type #"ELB"
  desired_capacity              = var.desired-capacity #2
  force_delete                  = var.force-delete #true
  launch_template {
    id                          = aws_launch_template.launch_template.id
  }
  vpc_zone_identifier           = var.subnets #[aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id]
  target_group_arns             = var.tg-arn #[module.load-balancer.alb-tg-arn]
}