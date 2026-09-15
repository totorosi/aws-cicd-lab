output "ec2_instance_id" {
  description = "GitHub Actions 워크플로의 SSM_INSTANCE_ID 에 넣을 값"
  value       = module.mumbai_network.ec2_instance_id
}
