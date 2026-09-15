# EC2 인스턴스가 SSM 으로 제어되고, 배포 아티팩트를 S3 에서 내려받기 위한 역할.
# 이 프로파일이 없으면 SSM 에 등록조차 되지 않아 GitHub Actions 의 send-command 가 실패한다.

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${local.tag_header}ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = { Name = "${local.tag_header}ec2-role" }
}

# SSM Session Manager / RunCommand 에 필요한 최소 권한 (AWS 관리형)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 배포 아티팩트(도커 이미지 tar)를 내려받기 위한 읽기 전용 권한.
# 버킷 이름이 지정되지 않으면 정책 자체를 만들지 않는다.
data "aws_iam_policy_document" "deploy_artifacts_read" {
  count = local.deploy_artifact_bucket != "" ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.deploy_artifact_bucket}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.deploy_artifact_bucket}"]
  }
}

resource "aws_iam_role_policy" "deploy_artifacts_read" {
  count = local.deploy_artifact_bucket != "" ? 1 : 0

  name   = "${local.tag_header}deploy-artifacts-read"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.deploy_artifacts_read[0].json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.tag_header}ec2-profile"
  role = aws_iam_role.ec2_role.name
}
