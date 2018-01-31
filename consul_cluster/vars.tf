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


variable "vpc_id" {
  type = "string"
  description = "VPC ID"
}

variable "environment" {
  type = "string"
  description = "describe your variable"
  default = "dev"
}

variable "pubkey_path" {
  description = "path to public key"
}


variable "consul_ami" {
  type = "string"
  description = "id of consul packer ami"
  default = "ami-ad62f9c2"
}

variable "subnet_ids" {
  type = "list"
  description = "list of subnet id's to create instances in"

}

