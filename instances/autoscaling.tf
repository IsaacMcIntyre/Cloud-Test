resource "aws_launch_template" "launch_template" {
image_id                        = "ami-053b5dc3907b8bd31"
  instance_type                 = "t2.micro"
  user_data                     = base64encode(data.template_file.user_data.rendered)
  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.sg_22_80.id]
    # subnet_id                   = var.subnet_id
  }
  # vpc_security_group_ids        = [aws_security_group.sg_22_80.id]
  key_name                      = aws_key_pair.deployer.key_name
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                          = "autoscaling_group"
  max_size                      = 2
  min_size                      = 1
  health_check_grace_period     = 300
  health_check_type             = "ELB"
  desired_capacity              = 1
  force_delete                  = true
  # placement_group               = aws_placement_group.placement_group.id
  launch_template {
    id                          = aws_launch_template.launch_template.id
  }
  vpc_zone_identifier           = [aws_subnet.subnet_public.id, aws_subnet.subnet_public-2.id]
  target_group_arns             = [aws_alb_target_group.group.arn]
}