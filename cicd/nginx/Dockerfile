FROM nginx:1.18.0-alpine

LABEL link1="https://github.com/nginx-modules/nginx_upstream_check_module"

RUN set -x \
  && tempDir="$(mktemp -d)" \
  && chown nobody:nobody $tempDir \
  && cd $tempDir \
  && wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
  && tar xzf nginx-${NGINX_VERSION}.tar.gz \
  && apk add --no-cache --virtual .build-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers curl gnupg libxslt-dev gd-dev geoip-dev git \
  && git clone --depth 1 --single-branch --branch master https://github.com/nginx-modules/nginx_upstream_check_module nginx-${NGINX_VERSION}/nginx_upstream_check_module \
  && CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  && CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Os} \
  && cd nginx-$NGINX_VERSION \
  && patch -p1 < nginx_upstream_check_module/check_1.16.1+.patch \
  && ./configure --with-compat $CONFARGS --add-module=nginx_upstream_check_module \
  && make \
  && make install \
  && cd / \
  && rm -rf $tempDir \
  && apk del .build-deps \
  && rm -rf /var/cache/apk/* \
  && mkdir /nginx_log \
  && touch /nginx_log/access.log \
  && touch /nginx_log/error.log \
  && ln -sf /nginx_log/access.log /var/log/nginx/access.log \
  && ln -sf /nginx_log/error.log /var/log/nginx/error.log
  # && ln -sf /dev/stdout /var/log/nginx/access.log \
  # && ln -sf /dev/stderr /var/log/nginx/error.log

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]