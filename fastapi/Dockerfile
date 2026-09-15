# 정적 사이트와 달리 파이썬 런타임이 필요하므로 공식 python 슬림 이미지를 쓴다.
# (amazonlinux:2023 로도 가능하지만 파이썬을 직접 깔아야 하고 이미지가 훨씬 커진다)
FROM python:3.12-slim

# 파이썬이 .pyc 를 남기지 않게 하고, 로그가 버퍼에 갇히지 않게 한다.
# 버퍼링을 끄지 않으면 컨테이너가 죽을 때 마지막 로그가 통째로 사라진다.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 의존성을 먼저 설치해 레이어 캐시를 살린다.
# 코드만 바뀌면 이 레이어는 재사용된다.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

# 루트로 돌리지 않는다. 볼륨 디렉토리는 이 사용자가 쓸 수 있어야 한다.
RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /data/uploads \
    && chown -R appuser:appuser /data
USER appuser

EXPOSE 8000

# --proxy-headers: 앞단에 ALB/nginx 가 있을 때 원래 클라이언트 IP 와 스킴을 살린다.
CMD ["uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--proxy-headers", \
     "--forwarded-allow-ips", "*"]
