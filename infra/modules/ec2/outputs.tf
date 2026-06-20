output "instance_ips" {
  value = { for k, v in aws_instance.server : k => v.public_ip }
}