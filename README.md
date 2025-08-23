## Quickstart

```bash
# This will start with an in memory database.

$ docker run -p 3567:3567 -d registry.supertokens.io/supertokens/supertokens-postgresql
```

## Configuration

You can use your own `config.yaml` file as a shared volume or pass the key-values as environment variables.

If you do both, only the shared `config.yaml` file will be considered.

#### Using environment variables

Available environment variables

- **Core**
  - API_KEYS
  - SUPERTOKENS_HOST
  - SUPERTOKENS_PORT
  - ACCESS_TOKEN_VALIDITY
  - ACCESS_TOKEN_BLACKLISTING
  - ACCESS_TOKEN_SIGNING_KEY_DYNAMIC
  - ACCESS_TOKEN_DYNAMIC_SIGNING_KEY_UPDATE_INTERVAL
  - REFRESH_TOKEN_VALIDITY
  - PASSWORD_RESET_TOKEN_LIFETIME
  - EMAIL_VERIFICATION_TOKEN_LIFETIME
  - INFO_LOG_PATH
  - ERROR_LOG_PATH
  - MAX_SERVER_POOL_SIZE
  - PASSWORDLESS_MAX_CODE_INPUT_ATTEMPTS
  - PASSWORDLESS_CODE_LIFETIME
  - DISABLE_TELEMETRY
  - OTEL_COLLECTOR_CONNECTION_URI
  - BASE_PATH
  - PASSWORD_HASHING_ALG
  - ARGON2_ITERATIONS
  - ARGON2_MEMORY_KB
  - ARGON2_PARALLELISM
  - ARGON2_HASHING_POOL_SIZE
  - BCRYPT_LOG_ROUNDS
  - LOG_LEVEL
  - FIREBASE_PASSWORD_HASHING_POOL_SIZE
  - FIREBASE_PASSWORD_HASHING_SIGNER_KEY
  - IP_ALLOW_REGEX
  - IP_DENY_REGEX
  - TOTP_MAX_ATTEMPTS
  - TOTP_RATE_LIMIT_COOLDOWN_SEC
  - SUPERTOKENS_SAAS_LOAD_ONLY_CUD
  - OAUTH_PROVIDER_PUBLIC_SERVICE_URL
  - OAUTH_PROVIDER_ADMIN_SERVICE_URL
  - OAUTH_PROVIDER_CONSENT_LOGIN_BASE_URL
  - OAUTH_PROVIDER_URL_CONFIGURED_IN_OAUTH_PROVIDER
  - OAUTH_CLIENT_SECRET_ENCRYPTION_KEY
  - BULK_MIGRATION_PARALLELISM
  - BULK_MIGRATION_BATCH_SIZE
  - BULK_MIGRATION_CRON_ENABLED
  - WEBAUTHN_RECOVER_ACCOUNT_TOKEN_LIFETIME
- **POSTGRESQL:**
  - POSTGRESQL_CONNECTION_URI
  - POSTGRESQL_USER
  - POSTGRESQL_PASSWORD
  - POSTGRESQL_PASSWORD_FILE
  - POSTGRESQL_CONNECTION_POOL_SIZE
  - POSTGRESQL_HOST
  - POSTGRESQL_PORT
  - POSTGRESQL_DATABASE_NAME
  - POSTGRESQL_TABLE_NAMES_PREFIX
  - POSTGRESQL_TABLE_SCHEMA
  - POSTGRESQL_IDLE_CONNECTION_TIMEOUT
  - POSTGRESQL_MINIMUM_IDLE_CONNECTIONS

```bash
docker run \
	-p 3567:3567 \
	-e POSTGRESQL_CONNECTION_URI="postgresql://username:password@host:port/dbName" \
	-d registry.supertokens.io/supertokens/supertokens-postgresql

# OR

docker run \
	-p 3567:3567 \
	-e POSTGRESQL_USER="postgresqlUser" \
	-e POSTGRESQL_HOST="192.168.1.2" \
	-e POSTGRESQL_PORT="5432" \
	-e POSTGRESQL_PASSWORD="password" \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```

#### Using custom config file

- In your `config.yaml` file, please make sure you store the following key / values:
  - `core_config_version: 0`
  - `host: "0.0.0.0"`
  - `postgresql_config_version: 0`
  - `info_log_path: null` (to log in docker logs)
  - `error_log_path: null` (to log in docker logs)
- The path for the `config.yaml` file in the container is `/usr/lib/supertokens/config.yaml`

```bash
docker run \
	-p 3567:3567 \
	-v /path/to/config.yaml:/usr/lib/supertokens/config.yaml \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```

## Logging

- By default, all the logs will be available via the `docker logs <container-name>` command.
- You can setup logging to a shared volume by:
  - Setting the `info_log_path` and `error_log_path` variables in your `config.yaml` file (or passing the values asn env variables).
  - Mounting the shared volume for the logging directory.

```bash
docker run \
	-p 3567:3567 \
	-v /path/to/logsFolder:/home/logsFolder \
	-e INFO_LOG_PATH="/home/logsFolder/info.log" \
	-e ERROR_LOG_PATH="/home/logsFolder/error.log" \
	-e POSTGRESQL_USER="postgresqlUser" \
	-e POSTGRESQL_PASSWORD="password" \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```

## Database setup

- Before you start this container, make sure to initialize your database.
- You do not need to ensure that the Postgresql database has started before this container is started. During bootup, SuperTokens will wait for ~1 hour for a Postgresql instance to be available.
- If `POSTGRESQL_USER`, `POSTGRESQL_PASSWORD`, `POSTGRESQL_PASSWORD_FILE` and `POSTGRESQL_CONNECTION_URI` are not provided, then SuperTokens will use an in memory database.

## Read-only root fs

- If you wish to run this container with a read-only root filesystem, you can do so.
- The container still needs a temp area, where it can write its stuff, and also needs to be able to execute from there.
- You will have to create a mount for `/lib/supertokens/temp/`

```bash
docker run \
	-p 3567:3567 \
	--mount source=/path/on/host/machine,destination=/lib/supertokens/temp/,type=bind \
	--read-only \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```

```bash
docker run \
	-p 3567:3567 \
	--tmpfs=/lib/supertokens/temp/:exec \
	--read-only \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```

## Running with tcp keepalive settings

```bash
docker run \
	-p 3567:3567 \
	--sysctl net.ipv4.tcp_keepalive_time=60 \
	--sysctl net.ipv4.tcp_keepalive_intvl=5 \
	--sysctl net.ipv4.tcp_keepalive_probes=3 \
	-d registry.supertokens.io/supertokens/supertokens-postgresql
```