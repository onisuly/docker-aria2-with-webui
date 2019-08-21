FROM alpine

LABEL maintainer "onisuly <onisuly@gmail.com>"

# For build image faster in China
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN mkdir -p /conf \
    && mkdir -p /data \
    && mkdir -p /preset-conf \
    && apk add --no-cache tzdata bash aria2 darkhttpd s6

RUN apk add --no-cache --virtual .install-deps curl unzip \
    && mkdir -p /aria2-ng \
    && ng_tag=$(curl -sX GET "https://api.github.com/repos/mayswind/AriaNg/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') \
    && curl -o /aria2-ng.zip -L https://github.com/mayswind/AriaNg/releases/download/${ng_tag}/AriaNg-${ng_tag}.zip \
    && unzip /aria2-ng.zip -d /aria2-ng \
    && rm /aria2-ng.zip \
    && apk del .install-deps

COPY files/start.sh /preset-conf/start.sh
COPY files/aria2.conf /preset-conf/aria2.conf

RUN chmod +x /preset-conf/start.sh

WORKDIR /

VOLUME ["/data"]
VOLUME ["/conf"]

EXPOSE 6800
EXPOSE 80

CMD ["/preset-conf/start.sh"]
HEALTHCHECK --interval=5s --timeout=1s CMD ps | grep darkhttpd | grep -v grep || exit 1
