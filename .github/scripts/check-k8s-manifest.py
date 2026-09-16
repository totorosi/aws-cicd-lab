"""쿠버네티스 매니페스트를 클러스터 없이 검사한다.

클러스터에 붙지 않고 할 수 있는 것만 본다. YAML 이 파싱되는지, 필요한 리소스가
다 있는지, 이미지가 자리표시자로 남아 있는지 정도다. 스키마 검증은 아니다.

배포 워크플로가 PR 에서 호출한다. 자격증명이 없어도 돌아야 하므로 kubectl 을
쓰지 않는다. kubectl 은 --dry-run=client 로도 API 서버에 리소스 종류를 물어보기
때문에 클러스터 없이는 쓸 수 없다.

    python3 .github/scripts/check-k8s-manifest.py docker/k8s/static-site.yaml
"""

import sys

import yaml

REQUIRED_KINDS = {"Namespace", "Deployment", "Service"}
IMAGE_PLACEHOLDER = "__IMAGE__"


def fail(message):
    print(f"검사 실패: {message}")
    raise SystemExit(1)


def main(path):
    with open(path, encoding="utf-8") as f:
        try:
            docs = [d for d in yaml.safe_load_all(f) if d]
        except yaml.YAMLError as exc:
            fail(f"YAML 을 읽지 못했습니다: {exc}")

    if not docs:
        fail("문서가 하나도 없습니다")

    kinds = [d.get("kind") for d in docs]
    print("문서:", ", ".join(str(k) for k in kinds))

    missing = REQUIRED_KINDS - set(kinds)
    if missing:
        fail(f"빠진 리소스: {', '.join(sorted(missing))}")

    deployment = next(d for d in docs if d.get("kind") == "Deployment")
    containers = deployment["spec"]["template"]["spec"]["containers"]

    image = containers[0].get("image")
    if image != IMAGE_PLACEHOLDER:
        # 이미지를 박아서 커밋하면 배포할 때마다 이 파일이 바뀐다.
        fail(f"이미지가 자리표시자가 아닙니다: {image}")

    # 셀렉터와 파드 레이블이 어긋나면 apply 는 되지만 파드가 하나도 안 뜬다.
    selector = deployment["spec"]["selector"]["matchLabels"]
    labels = deployment["spec"]["template"]["metadata"]["labels"]
    if not selector.items() <= labels.items():
        fail(f"셀렉터 {selector} 와 파드 레이블 {labels} 이 맞지 않습니다")

    service = next(d for d in docs if d.get("kind") == "Service")
    if not service["spec"]["selector"].items() <= labels.items():
        fail("Service 셀렉터가 파드 레이블과 맞지 않습니다")

    # LoadBalancer 로 바꾸면 ELB 가 생긴다. terraform state 밖이라 지우지 않고
    # destroy 하면 VPC 삭제가 멈춘다. 모르고 바뀌는 일이 없도록 여기서 잡는다.
    service_type = service["spec"].get("type", "ClusterIP")
    if service_type != "ClusterIP":
        fail(
            f"Service 타입이 {service_type} 입니다. "
            "의도한 변경이라면 이 검사와 워크플로의 확인 단계를 함께 고쳐야 합니다"
        )

    print("이상 없음")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("사용법: check-k8s-manifest.py <매니페스트 경로>")
    main(sys.argv[1])
