locals {
  sistema_usuarios = ["andre", "senior_devops"]
}

resource "random_password" "user_passwords" {
  for_each         = toset(local.sistema_usuarios)
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+"
}

resource "aws_ssm_parameter" "user_passwords_ssm" {
  for_each = toset(local.sistema_usuarios)
  
  name        = "/infra/${terraform.workspace}/users/${each.key}/password"
  description = "Senha gerada automaticamente para o usuario ${each.key}"
  type        = "SecureString"
  value       = random_password.user_passwords[each.key].result

  tags = {
    Environment = terraform.workspace
    ManagedBy   = "Terraform"
  }
}

module "s3" {
  source = "./modules/s3"
  bucket = var.bucket_name
}

module "ec2" {
  source      = "./modules/ec2"
  environment = terraform.workspace
  bucket_name = module.s3.bucket_name
  ami_id      = "ami-0aa2bfca464a9be6b"

  servers = {
    web = {
      role  = "nginx"
      ports = [22, 80]
    }
    db = {
      role  = "database"
      ports = [22, 3306]
    }
    monitoring = {
      role  = "zabbix-grafana"
      ports = [22, 80, 3000, 10050, 10051]
    }
  }
}
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory.ini"
  content  = templatefile("${path.module}/inventory.tpl", {
    web_ip        = module.ec2.instance_ips["web"]
    db_ip         = module.ec2.instance_ips["db"]
    monitoring_ip = module.ec2.instance_ips["monitoring"]
  })
}
output "infra_ips" {
  value = module.ec2.instance_ips
}
