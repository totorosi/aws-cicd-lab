output "ec2_instance_id" {
  description = "GitHub Actions 워크플로의 SSM_INSTANCE_ID 에 넣을 값"
  value       = module.mumbai_network.ec2_instance_id
}

output "eks_cluster_name" {
  description = "EKS 클러스터 이름. create_eks 가 false 면 null 이다."
  value       = one(module.eks[*].cluster_name)
}

output "eks_kubeconfig_command" {
  description = "kubectl 을 클러스터에 붙이는 명령"
  value       = one(module.eks[*].kubeconfig_command)
}
