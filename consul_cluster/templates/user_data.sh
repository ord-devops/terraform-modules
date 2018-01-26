#!/bin/bash


# Setup ssh configuration
cat > /root/.ssh/github_rsa << EOF
${ github_key }
EOF

cat > /root/.ssh/config << EOF
Host github.com
  HostName github.com
  IdentityFile ~/.ssh/github_rsa
  User git 
EOF

chmod 0600 /root/.ssh/github_rsa
chmod 0644 /root/.ssh/config
ssh-keyscan github.com >> /root/.ssh/known_hosts

# Ansible configuration
yum update -y
yum install git -y
yum install gcc libffi-devel python-devel openssl-devel -y
easy_install pip
pip install -U setuptools
pip install -U awscli
pip install ansible==${ansible_version}


# Setup aws cli default region for root user
mkdir -p /root/.aws
cat > /root/.aws/config << EOF
[default]
output = json
region = eu-central-1
EOF

export HOME=/root


# Run ansible-pull
cd /opt
git clone ${ansible_pull_repo} ansible
cd /opt/ansible
ansible-playbook local.yml 2>&1 | tee -a /var/log/ansible-pull.log

# Custom userdata
${custom_userdata}