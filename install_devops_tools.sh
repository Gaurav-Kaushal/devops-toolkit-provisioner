#!/bin/bash

LOG_FILE="/var/log/devops-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting DevOps tools installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if not already installed
install_package() {
    if ! command_exists "$1"; then
        echo "Installing $1..."
        sudo apt-get install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

# Update and upgrade system
sudo apt-get update -y && sudo apt-get upgrade -y

# Install dependencies
install_package apt-transport-https
install_package ca-certificates
install_package curl
install_package gnupg
install_package software-properties-common

# Install Docker
if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    install_package docker-ce
    install_package docker-ce-cli
    install_package containerd.io
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed."
fi

# Install Kubernetes (kubectl)
if ! command_exists kubectl; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi

# Install Minikube
if ! command_exists minikube; then
    echo "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

# Install Terraform
TERRAFORM_VERSION=${TERRAFORM_VERSION:-"1.5.7"}
if ! command_exists terraform; then
    echo "Installing Terraform..."
    curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
fi

# Install Helm
if ! command_exists helm; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Install AWS CLI
if ! command_exists aws; then
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
fi

# Install Git
install_package git

# Install Ansible
install_package ansible

# Install Jenkins
if ! command_exists jenkins; then
    echo "Installing Jenkins..."
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    install_package jenkins
fi

# Install Java (Required for Jenkins)
install_package openjdk-11-jdk

# Install Node.js
if ! command_exists node; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    install_package nodejs
fi

# Install Python3 and Pip
install_package python3
install_package python3-pip

# Install Azure CLI
if ! command_exists az; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Install Google Cloud SDK
if ! command_exists gcloud; then
    echo "Installing Google Cloud SDK..."
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.gpg > /dev/null
    sudo apt-get update -y
    install_package google-cloud-sdk
fi

# Print installed versions
echo "=== Installed Tools ==="
docker --version 2>/dev/null
kubectl version --client --short 2>/dev/null
minikube version 2>/dev/null
terraform --version 2>/dev/null
helm version --short 2>/dev/null
aws --version 2>/dev/null
git --version 2>/dev/null
ansible --version 2>/dev/null
java -version 2>/dev/null
node --version 2>/dev/null
python3 --version 2>/dev/null
az --version 2>/dev/null
gcloud --version 2>/dev/null

echo "Installation complete! Please log out and log back in for Docker group changes to take effect."

