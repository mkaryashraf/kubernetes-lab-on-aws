output "cp_ip_addr" {
  value = aws_instance.cp.public_ip
}

output "wp1_ip_addr" {
  value = aws_instance.w_1.public_ip
}

output "wp2_ip_addr" {
  value = aws_instance.w_2.public_ip
}

output "default_vpc_id" {
  value = data.aws_vpc.default_vpc.id
}