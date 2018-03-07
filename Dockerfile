FROM debian:stretch-slim

RUN groupadd -r memcache && useradd -r -g memcache memcache

ENV MEMCACHED_VERSION 1.5.5
ENV MEMCACHED_SHA1 975a5ba57bfc8331bbc3d8f92da969f35a7acf1b

COPY memcached-1.5.5.tar.gz /memcached.tar.gz

RUN set -x \
	\
	&& export DEBIAN_FRONTEND=noninteractive \
	\
	&& buildDeps=' \
		ca-certificates \
		dpkg-dev \
		libc6-dev \
		libevent-dev \
		libsasl2-dev \
		libssl1.0.2 \
		libpcap0.8 \
		gcc \
		make \
		perl \
		tcpdump \
		net-tools \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends \
	# && rm -rf /var/lib/apt/lists/* \
	\
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	\
	&& cd /usr/src/memcached \
	\
	&& ./configure \
		--build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
		--enable-sasl \
	&& make -j "$(nproc)" \
	\
	&& make install \
	\
	&& cd / && rm -rf /usr/src/memcached \
	\
	&& apt-mark manual \
		libevent-2.0-5 \
		libsasl2-2 \
	&& apt-get purge -y --auto-remove $buildDeps \
	\
	&& memcached -V

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]