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

variable "vpc_name" {
  type = "string"
  description = "name of the vpc"
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

variable "privkey_path" {
  description = "path to private key"
}

variable "github_key" {
  type = "string"
  description = "path to github private key"
  default = "~/.ssh/github_rsa"
}

variable "consul_encryption_key_path" {
  type = "string"
  description = "path to encrypted consul encryption key"
}

variable "custom_userdata" {
  type = "string"
  description = "userdata for inserting in cloud init script"
  default = ""
}

variable "ansible_version" {
  description = "Ansible version to install"
}

variable "ansible_pull_repo" {
  description = "repository to pull ansible playbook from"
}