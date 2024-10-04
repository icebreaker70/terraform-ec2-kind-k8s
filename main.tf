#--------------
# Provider 설정
#--------------
provider "aws" {
  region  = "ap-northeast-2" # 원하는 AWS 리전으로 변경
  profile = "devops"
}


#--------------
# VPC 생성
#--------------
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Kans_VPC"
  }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# 퍼블릭 서브넷 생성 (3개)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.0.0/23"
  availability_zone       = "ap-northeast-2a" # 사용하려는 가용 영역으로 변경
  map_public_ip_on_launch = true

  tags = {
    Name = "kans_public_subnet_1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "192.168.2.0/23"
  availability_zone       = "ap-northeast-2c" # 사용하려는 가용 영역으로 변경
  map_public_ip_on_launch = true

  tags = {
    Name = "kans_public_subnet_2"
  }
}

# 라우팅 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# 라우팅 테이블을 서브넷에 연결
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


#-------------------
# Security Group 생성
#-------------------
resource "aws_security_group" "k8s_security_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["125.187.158.81/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Kans-SG"
  }
}


#-------------------
# EC2 인스턴스 생성
#-------------------
resource "aws_instance" "k8s_node" {
  ami             = "ami-040c33c6a51fd5d96" # Ubuntu 24.04 LTS AMI
  instance_type   = "t3.medium"
  subnet_id       = aws_subnet.public_1.id
  security_groups = [aws_security_group.k8s_security_group.id]
  key_name        = "martha" # 이미 생성된 martha.pem을 사용하는 키

  tags = {
    Name = "MyServer"
  }

  associate_public_ip_address = true


  # 파일을 인스턴스에 복사
  provisioner "file" {
    source      = "init_cfg.sh" # 로컬에서 작성한 스크립트 경로
    destination = "/home/ubuntu/init_cfg.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/martha.pem")
      host        = self.public_ip
    }
  }

  # 복사한 스크립트를 실행
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/martha.pem")
      host        = self.public_ip
    }

    inline = [
      "chmod +x /home/ubuntu/init_cfg.sh",
      "sudo /home/ubuntu/init_cfg.sh" # 업로드한 스크립트를 실행
    ]
  }
}


#-----------------
# EC2 EIP를 출력
#-----------------
output "ec2_public_ip" {
  description = "Public IP addresses of the EC2 instance"
  value       = aws_instance.k8s_node.public_ip
}
