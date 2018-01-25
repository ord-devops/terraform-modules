provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


data "aws_subnet" "private_1a" {
  filter {
    name = "tag:Name"
    values = "${var.vpc_name} private-1a"
  }
}

data "aws_subnet" "private_1b" {
  filter {
    name = "tag:Name"
    values = "${var.vpc_name} private-1b"
  }
}

data "aws_subnet" "private_1c" {
  filter {
    name = "tag:Name"
    values = "${var.vpc_name} private-1c"
  }
}

resource "aws_key_pair" "centos" {
  key_name   = "centos-key"
  public_key = "${file(var.pubkey_path)}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh")}"
  vars {
    custom_userdata = "${var.custom_userdata}"
    ansible_version = "${var.ansible_version}"
    ansible_pull_repo = "${var.ansible_pull_repo}"
      }
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


# Consul IAM instance role definition

resource "aws_iam_instance_profile" "consul_profile" {
  name = "${aws_iam_role.consul_role.name}"
  role = "${aws_iam_role.consul_role.name}"
}

resource "aws_iam_role" "consul_role" {
  name               = "consul_role"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}


resource "aws_iam_role_policy_attachment" "consul_policy_ec2_readonly" {
  role       = "${aws_iam_role.consul_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Security group def, probably want this to be moved to a sep file

resource "aws_security_group" "consul" {
  name        = "consul"
  description = "consul allow ssh traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  tags {
    Name = "consul"
  }
}

resource "aws_security_group_rule" "consul_ssh" {
  type = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow ssh access to consul"
}

resource "aws_security_group_rule" "consul_rpc_lan_wan_tcp" {
  type = "ingress"
  from_port   = 8300
  to_port     = 8302
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow rpc, lan and wan access to consul"
}

resource "aws_security_group_rule" "consul_lan_wan_udp" {
  type = "ingress"
  from_port   = 8301
  to_port     = 8302
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow lan and wan access to consul via udp"
}

resource "aws_security_group_rule" "consul_http" {
  type = "ingress"
  from_port   = 8500
  to_port     = 8500
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow http access to consul via tcp"
}

resource "aws_security_group_rule" "consul_dns_tcp" {
  type = "ingress"
  from_port   = 8600
  to_port     = 8600
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow dns access to consul via tcp"
}

resource "aws_security_group_rule" "consul_dns_udp" {
  type = "ingress"
  from_port   = 8600
  to_port     = 8600
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
  description = "allow dns access to consul via udp"
}

resource "aws_security_group_rule" "egress_consul" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "all"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = "${aws_security_group.consul.id}"
}



# Consul server autoscaling group
resource "aws_launch_configuration" "consul" {
  name_prefix = "consul_"
  image_id           = "${data.aws_ami.centos.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.consul.id}"]
  associate_public_ip_address = false
  key_name = "${aws_key_pair.centos.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.consul_profile.name}"
  user_data            = "${data.template_file.user_data.rendered}"
  
  root_block_device {
    volume_type = "gp2"
    delete_on_termination = true
  }
  # aws_launch_configuration can not be modified.
  # Therefore we use create_before_destroy so that a new modified aws_launch_configuration can be created 
  # before the old one get's destroyed. That's why we use name_prefix instead of name.
  lifecycle {
    create_before_destroy = true
  }

  
}

resource "aws_autoscaling_group" "consul" {
  name                 = "consul"
  max_size             = "3"
  min_size             = "0"
  desired_capacity     = "3"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.consul.id}"
  vpc_zone_identifier  = ["${data.aws_subnet.private_1a.id}","${data.aws_subnet.private_1b.id}","${data.aws_subnet.private_1c.id}"]

  tag {
    key                 = "Name"
    value               = "consul"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "environment"
    value               = "${var.environment}"
    propagate_at_launch = "true"
  }

  tag {
    key                 = "role"
    value               = "consul_server"
    propagate_at_launch = "true"
  }

}