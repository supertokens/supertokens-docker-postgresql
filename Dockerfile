FROM ubuntu:bionic-20200219 as tmp

# Railway env vars
ARG POSTGRESQL_CONNECTION_URI
ENV POSTGRESQL_CONNECTION_URI=$POSTGRESQL_CONNECTION_URI
ARG POSTGRESQL_TABLE_NAMES_PREFIX
ENV POSTGRESQL_TABLE_NAMES_PREFIX=$POSTGRESQL_TABLE_NAMES_PREFIX
ARG PORT
ENV SUPERTOKENS_PORT=$PORT

# Static config vars
ENV DISABLE_TELEMETRY=true
# This is the default of 100 days (in minutes), just making it explicit
ENV REFRESH_TOKEN_VALIDITY=144000
# 6 hours between refreshes (in seconds)
ENV ACCESS_TOKEN_VALIDITY=21600

ENV MAX_SERVER_POOL_SIZE=25
ENV POSTGRESQL_CONNECTION_POOL_SIZE=20


ARG PLUGIN_NAME=postgresql
ARG PLAN_TYPE=FREE
ARG CORE_VERSION=6.0.11
ARG PLUGIN_VERSION=4.0.2
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
FROM debian:bullseye-slim
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
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supertokens", "start"]
