data "aws_ami" "ubuntu_24_04" {
  most_recent = true
  owners      = ["099720109477"] # ID oficial da Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = "${var.environment}-ssh-key"
  public_key = tls_private_key.pk.public_key_openssh
}

# Salva a chave privada no S3 criado pelo outro módulo para fins de backup
resource "aws_s3_object" "private_key" {
  bucket  = var.bucket_name
  key     = "ssh-keys/${var.environment}-private-key.pem"
  content = tls_private_key.pk.private_key_pem
}

resource "aws_instance" "server" {
  for_each               = var.servers
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.kp.key_name
  vpc_security_group_ids = [aws_security_group.sg[each.key].id]

  tags = {
    Name = "${var.environment}-${each.key}"
    Role = each.value.role
  }
}

resource "aws_security_group" "sg" {
  for_each    = var.servers
  name        = "${var.environment}-${each.key}-sg"
  description = "Security Group para ${each.key}"

  dynamic "ingress" {
    for_each = each.value.ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}