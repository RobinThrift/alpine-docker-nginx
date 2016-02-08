FROM hypriot/rpi-alpine-scratch

ENV NGINX_VERSION 1.9.10

ENV GPG_KEYS B0F4253373F8F6F510D42178520A9993A1C052F8

RUN \
	apk update && apk upgrade \
	&& addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg \
		geoip-dev \
	&& wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz \
	&& gunzip GeoIP.dat.gz \
	&& mkdir -p /usr/share/GeoIP \
	&& mv GeoIP.dat /usr/share/GeoIP/GeoIP.dat \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& gpg --verify nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz* \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
			--conf-path=/etc/nginx/nginx.conf \
			--error-log-path=/var/log/nginx/error.log \
			--http-log-path=/var/log/nginx/access.log \
			--pid-path=/var/run/nginx.pid \
			--lock-path=/var/run/nginx.lock \
			--http-client-body-temp-path=/var/cache/nginx/client_temp \
			--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
			--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
			--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
			--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
			--user=nginx \
			--group=nginx \
			--with-http_ssl_module \
			--with-http_realip_module \
			--with-http_addition_module \
			--with-http_sub_module \
			--with-http_dav_module \
			--with-http_flv_module \
			--with-http_mp4_module \
			--with-http_gunzip_module \
			--with-http_gzip_static_module \
			--with-http_random_index_module \
			--with-http_secure_link_module \
			--with-http_stub_status_module \
			--with-http_auth_request_module \
			--with-http_geoip_module \
			--with-threads \
			--with-stream \
			--with-stream_ssl_module \
			--with-http_slice_module \
			--with-mail \
			--with-mail_ssl_module \
			--with-file-aio \
			--with-http_v2_module \
			--with-cc-opt="-g -O2 -fstack-protector-strong -Wformat -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -Werror=format-security " \
			--with-ld-opt="-Wl,-z,relro -Wl,--as-needed" \
			--with-ipv6 \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& strip /usr/sbin/nginx* \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/sbin/nginx \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" \
	&& apk add --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& rm -rf /usr/src/nginx-* \
	&& rm -rf /var/cache/apk/* \
	\
	# forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
