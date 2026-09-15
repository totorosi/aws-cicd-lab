resource "aws_instance" "ec2_instance" {
  ami           = local.ami_id
  instance_type = "t3.micro"

  # 퍼블릭 서브넷의 ID를 참조하여 연결합니다.
  subnet_id = aws_subnet.this["public${split("-", local.azs[0])[2]}"].id
  # 퍼블릭 IP 활성화
  associate_public_ip_address = true
  # NAT 인스턴스 필수 설정: 소스/대상 확인 비활성화
  source_dest_check = false

  # 볼륨 지정
  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    delete_on_termination = true # 인스턴스 삭제 시 함께 삭제
  }

  key_name = var.ssh_key

  # SSM 제어와 S3 아티팩트 다운로드에 필요
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # 보안 그룹 정의
  vpc_security_group_ids = [
    aws_security_group.ssh_sg.id,
    aws_security_group.external_alb_sg.id
  ]

  # User Data
  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y nginx unzip docker
# dnf 는 설치만 하고 서비스를 띄우지 않으므로 직접 활성화한다.
systemctl enable --now nginx
systemctl enable --now docker
# SSM 명령은 root 로 실행되므로 배포에는 불필요하지만, 수동 확인용으로 추가한다.
usermod -aG docker ec2-user
EOF
  tags      = { Name = "${local.tag_header}instance" }
}
