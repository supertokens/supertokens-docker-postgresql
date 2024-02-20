FROM ubuntu:bionic-20200219 as tmp
ARG PLUGIN_NAME=postgresql
ARG PLAN_TYPE=FREE
ARG CORE_VERSION=7.0.18
ARG PLUGIN_VERSION=5.0.8
RUN apt-get update && apt-get install -y curl zip
RUN OS= && dpkgArch="$(dpkg --print-architecture)" && \
	case "${dpkgArch##*-}" in \
	amd64) OS='linux';; \
	arm64) OS='linux-arm';; \
	*) OS='linux';; \
	esac && \
	curl -o supertokens.zip -s -X GET \
	"https://api.supertokens.io/0/app/download?pluginName=$PLUGIN_NAME&os=$OS&mode=DEV&binary=$PLAN_TYPE&targetCore=$CORE_VERSION&targetPlugin=$PLUGIN_VERSION" \
	-H "api-version: 0"
RUN unzip supertokens.zip
RUN cd supertokens && ./install
FROM debian:bookworm-slim
RUN groupadd supertokens && useradd -m -s /bin/bash -g supertokens supertokens
RUN apt-get update && apt-get install -y --no-install-recommends gnupg dirmngr && rm -rf /var/lib/apt/lists/*
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& gpgconf --kill all \
	&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& apt-get purge -y --auto-remove ca-certificates wget
COPY --from=tmp --chown=supertokens /usr/lib/supertokens /usr/lib/supertokens
COPY --from=tmp --chown=supertokens /usr/bin/supertokens /usr/bin/supertokens
COPY docker-entrypoint.sh /usr/local/bin/
RUN echo "$(md5sum /usr/lib/supertokens/config.yaml | awk '{ print $1 }')" >> /CONFIG_HASH
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
EXPOSE 3567
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supertokens", "start"]