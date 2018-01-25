variable "aws_region" {
  type = "string"
  description = "region to create VPC in"
  default = "eu-central-1"
}

variable "aws_profile" {
  type = "string"
  description = "aws credentials profile to use"
  default = "dev"
}

variable "cidr_block" {
  description = "The VPC CIDR block"
}

variable "vpc_name" {
  description = "The VPC name"
}

variable "vpc_env" {
  description = "The VPC environment"
}
