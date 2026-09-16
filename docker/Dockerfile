FROM nginx:1.31.3-alpine

# 공식 nginx 이미지는 nginx 설치, 로그를 stdout/stderr 로 넘기는 심볼릭 링크,
# 그리고 daemon off 로 띄우는 CMD 까지 이미 갖고 있다.
# 그래서 여기서는 웹루트만 우리 것으로 바꾼다.
#
# 예전 amazonlinux 베이스에서는 그 셋을 직접 해야 했다. 베이스를 바꾸면
# 그때 쓰던 dnf 명령은 알파인에 없어서 빌드가 그 줄에서 멈춘다.

# 기본 이미지의 index.html, 50x.html 을 먼저 치운다.
# COPY 는 같은 이름만 덮어쓰므로, 지우지 않으면 50x.html 이 그대로 남는다.
RUN rm -rf /usr/share/nginx/html/*

COPY ./nginx/html /usr/share/nginx/html/

EXPOSE 80
