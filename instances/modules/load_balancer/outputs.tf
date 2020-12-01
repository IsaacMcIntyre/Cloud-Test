output "sg_id" {
  value = aws_security_group.sg.id
}

output "alb_tg_arn" {
  value = aws_alb_target_group.group.arn
}