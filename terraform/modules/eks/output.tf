output "cluster_name" {
  description = "클러스터 이름"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "쿠버네티스 API 서버 주소"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "EKS 가 만든 클러스터 보안 그룹. 노드와 컨트롤 플레인 통신에 쓰인다."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_name" {
  description = "관리형 노드 그룹 이름"
  value       = aws_eks_node_group.this.node_group_name
}

output "kubeconfig_command" {
  description = "kubectl 을 이 클러스터에 붙이는 명령"
  value       = "aws eks update-kubeconfig --region ${local.region} --name ${aws_eks_cluster.this.name}"
}
