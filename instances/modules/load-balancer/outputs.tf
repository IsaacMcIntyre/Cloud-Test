output "sg-id" {
  value = aws_security_group.sg.id
}

output "alb-tg-arn" {
  value = aws_alb_target_group.group.arn
}