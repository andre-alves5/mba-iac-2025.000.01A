variable "environment" { type = string }
variable "bucket_name" { type = string }
variable "ami_id" { type = string }
variable "servers" {
  type = map(object({
    role  = string
    ports = list(number)
  }))
}