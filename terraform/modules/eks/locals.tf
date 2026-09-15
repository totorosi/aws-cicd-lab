locals {
  tag_header   = var.tag_header
  cluster_name = "${var.tag_header}eks"
  region       = data.aws_region.current.region
}

data "aws_region" "current" {}
