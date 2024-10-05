# terraform-ec2-kind-k8s
Terraform 이용하여 EC2생성 후 Kind로 K8S 구성


# Terraform 실행 방법 k8S 설치
## Terraform 코드 실행
terraform init && terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform state list
terraform output

## AWS EC2 접속
ssh -i ~/.ssh/martha.pem ubuntu@$(terraform output -raw ec2_public_ip) 


# Kind K8S Cluster 생성 (EC2 접속 후)
## kind manifest 복사
scp -i \~/.ssh/martha.pem kind-svc.yaml ubuntu@$(terraform output -raw ec2_public_ip):\~/kind-svc.yaml<br>
mv ~ubuntu/kind-svc.yaml .

## k8s 클러스터 설치
kind create cluster --config kind-svc.yaml --name myk8s --image kindest/node:v1.31.0
docker ps
kubectl get nodes -o wide

## 노드에 기본 툴 설치
docker exec -it myk8s-control-plane sh -c 'apt update && apt install tree psmisc lsof wget bsdmainutils bridge-utils net-tools dnsutils ipset ipvsadm nfacct tcpdump ngrep iputils-ping arping git vim arp-scan -y'

for i in worker worker2 worker3; do echo ">> node myk8s-$i <<"; docker exec -it myk8s-$i sh -c 'apt update && apt install tree psmisc lsof wget bsdmainutils bridge-utils net-tools dnsutils ipset ipvsadm nfacct tcpdump ngrep iputils-ping arping -y'; echo; done

# 자원삭제 (Local)
terraform destroy -auto-approve
