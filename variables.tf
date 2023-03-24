variable "name" {
  description = "Enter the value to be used with Name tag and Name arguments"
}

locals {
  tags = {
    Name = var.name
  }
}

variable "vpc_id" {
  default = "vpc-0ce7889ae8fafd3f6"
}