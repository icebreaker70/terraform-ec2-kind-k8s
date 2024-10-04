#!/bin/bash
hostnamectl --static set-hostname MyServer

# Config convenience
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/ubuntu/.bashrc
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

# Disable AppArmor
systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor

# Install packages
apt update && apt-get install bridge-utils net-tools jq tree unzip kubecolor tcpdump -y

# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/bin

# Install Docker Engine
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
curl -fsSL https://get.docker.com | sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Alias kubectl to k
echo 'alias kc=kubecolor' >> /etc/profile
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -o default -F __start_kubectl k' >> /etc/profile

# kubectl Source the completion
source <(kubectl completion bash)
echo 'source <(kubectl completion bash)' >> /etc/profile

# Install Kubectx & Kubens
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

# Install Kubeps & Setting PS1
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1
cat <<"EOT" >> ~/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT

# To increase Resource limits by kind k8s
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
echo 'fs.inotify.max_user_watches=524288' > /etc/sysctl.d/99-kind.conf
echo 'fs.inotify.max_user_instances=512'  > /etc/sysctl.d/99-kind.conf
sysctl -p
sysctl --system

