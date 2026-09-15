output "network" {
  description = "VPC와 Subnet 리소스 전체 객체"
  value = {
    vpc     = aws_vpc.this
    subnets = aws_subnet.this
  }
}

output "ec2_instance_id" {
  description = "GitHub Actions 워크플로의 SSM_INSTANCE_ID 에 넣을 값"
  value       = one(aws_instance.ec2_instance[*].id)
}

output "mysql_sg" {
  value = aws_security_group.mysql_sg.id
}

output "eks_node_sg" {
  description = "EKS 노드에 붙일 보안 그룹"
  value       = aws_security_group.eks_node_sg.id
}
