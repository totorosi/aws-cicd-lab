FROM amazonlinux:2023

# nginx 는 AL2023 기본 저장소에 있다. 캐시를 남기면 레이어만 커지므로 같은 RUN 에서 정리한다.
RUN dnf install -y nginx \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# 패키지로 설치한 nginx 는 로그를 파일로 남긴다.
# 컨테이너 로그(docker logs)로 보이도록 표준출력/표준에러로 연결한다.
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# RPM 이 웹루트에 깔아두는 기본 파일(404.html, icons/, poweredby.png 심볼릭 링크 등)을
# 치우고 우리 파일만 남긴다. 볼륨으로 꺼낼 때 심볼릭 링크가 걸림돌이 되기도 한다.
RUN rm -rf /usr/share/nginx/html/*

COPY ./nginx/html /usr/share/nginx/html/

EXPOSE 80

# 공식 nginx 이미지와 달리 CMD 가 없으므로 직접 지정한다.
# 데몬으로 띄우면 PID 1 이 즉시 종료되어 컨테이너가 죽는다.
CMD ["nginx", "-g", "daemon off;"]
