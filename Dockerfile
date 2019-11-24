FROM alpine AS base

LABEL maintainer "onisuly <onisuly@gmail.com>"

# For build image faster in China
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN mkdir -p /conf \
    && mkdir -p /data \
    && mkdir -p /preset-conf \
    && apk add --no-cache tzdata bash darkhttpd s6 ca-certificates gnutls expat sqlite-libs c-ares zlib nettle libssh2 libgcc libstdc++

FROM base AS build

RUN apk add --no-cache --virtual .install-deps curl unzip build-base automake autoconf gettext-dev git libtool gnutls-dev expat-dev sqlite-dev c-ares-dev zlib-dev nettle-dev libssh2-dev \
    && tag_name=$(curl -sX GET "https://api.github.com/repos/aria2/aria2/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') \
    && file_name="${tag_name/release/aria2}" \
    && cd /tmp \
    && curl -O -L https://github.com/aria2/aria2/releases/download/${tag_name}/${file_name}.tar.gz \
    && tar -zxvf ${file_name}.tar.gz \
    && cd ${file_name} \
    && autoreconf -i \
    && ./configure CXXFLAGS="-Os -s" --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man --infodir=/usr/share/info --localstatedir=/var --disable-nls --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt \
    && make -j $(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /tmp/${file_name}* \
    && mkdir -p /aria2-ng \
    && ng_tag=$(curl -sX GET "https://api.github.com/repos/mayswind/AriaNg/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]') \
    && curl -o /aria2-ng.zip -L https://github.com/mayswind/AriaNg/releases/download/${ng_tag}/AriaNg-${ng_tag}.zip \
    && unzip /aria2-ng.zip -d /aria2-ng \
    && rm /aria2-ng.zip \
    && apk del .install-deps

FROM base AS release

COPY --from=build /usr/bin /usr/bin
COPY --from=build /bin /bin
COPY --from=build /aria2-ng /aria2-ng

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
