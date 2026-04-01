#!/bin/bash
set -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script at $(date)"

# -----------------------------
# 1. System updates & base packages
# -----------------------------
apt-get update -y
apt-get upgrade -y

# Enable universe repository (for packages like ansible, maven)
add-apt-repository universe -y
apt-get update -y

# Install essential tools (gnupg is already installed, but ensure it's there)
apt-get install -y git wget unzip curl software-properties-common apt-transport-https ca-certificates lsb-release gnupg

# -----------------------------
# 2. Java (Jenkins requirement)
# -----------------------------
apt-get install -y openjdk-17-jdk
java -version

# -----------------------------
# 3. Node.js and npm
# -----------------------------
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
node -v
npm -v

# -----------------------------
# 4. Jenkins (fixed GPG key handling)
# -----------------------------
# Download the key and convert to binary format for apt
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# -----------------------------
# 5. Terraform (HashiCorp repo)
# -----------------------------
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
apt-get update -y
apt-get install -y terraform
terraform -v

# -----------------------------
# 6. Maven
# -----------------------------
apt-get install -y maven
mvn -v

# -----------------------------
# 7. Ansible
# -----------------------------
apt-get install -y ansible
ansible --version

# -----------------------------
# 8. kubectl
# -----------------------------
curl -LO "https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

# -----------------------------
# 9. eksctl
# -----------------------------
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin/
eksctl version

# -----------------------------
# 10. Helm
# -----------------------------
wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
rm -rf helm-v3.6.0-linux-amd64.tar.gz linux-amd64
helm version

# -----------------------------
# 11. Docker & Docker Compose
# -----------------------------
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
if id "ubuntu" &>/dev/null; then
    usermod -aG docker ubuntu
else
    echo "User 'ubuntu' not found; docker group may need manual setup."
fi
chmod 777 /var/run/docker.sock
docker --version

curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# -----------------------------
# 12. SonarQube (Docker container)
# -----------------------------
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
docker ps

# -----------------------------
# 13. Trivy
# -----------------------------
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.deb
dpkg -i trivy_0.48.3_Linux-64bit.deb
rm -f trivy_0.48.3_Linux-64bit.deb
trivy --version

# -----------------------------
# 14. Vault (official HashiCorp repo)
# -----------------------------
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y vault
vault --version

# -----------------------------
# 15. MariaDB
# -----------------------------
apt-get install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb
mysql --version

# -----------------------------
# 16. PostgreSQL
# -----------------------------
apt-get install -y postgresql postgresql-contrib
systemctl enable postgresql
systemctl start postgresql
psql --version

# -----------------------------
# 17. AWS CLI v2
# -----------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws
aws --version

# -----------------------------
# 18. Kubernetes tools (skip until cluster is ready)
# -----------------------------
echo "Skipping ArgoCD and Prometheus installation because no EKS cluster exists yet."
echo "You can install them manually later."

echo "✅ Initialization script completed successfully at $(date)"
