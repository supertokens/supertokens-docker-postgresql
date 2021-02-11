## Quickstart
```bash
# This will start with an in memory database.

$ docker run -p 3567:3567 -d supertokens/supertokens-postgresql
```

## Configuration
You can use your own `config.yaml` file as a shared volume or pass the key-values as environment variables. 

If you do both, only the shared `config.yaml` file will be considered.
  
#### Using environment variable
Available environment variables
- **Core**
	- API\_KEYS
	- SUPERTOKENS\_HOST
	- SUPERTOKENS\_PORT
	- ACCESS\_TOKEN\_VALIDITY
	- ACCESS\_TOKEN\_BLACKLISTING
	- ACCESS\_TOKEN\_SIGNING\_KEY\_DYNAMIC
	- ACCESS\_TOKEN\_SIGNING\_KEY\_UPDATE\_INTERVAL
	- REFRESH\_TOKEN\_VALIDITY
	- INFO\_LOG\_PATH
	- ERROR\_LOG\_PATH
    - MAX\_SERVER\_POOL\_SIZE
	- DISABLE\_TELEMETRY
- **POSTGRESQL:**	
	- POSTGRESQL\_USER
	- POSTGRESQL\_PASSWORD
	- POSTGRESQL\_CONNECTION\_POOL\_SIZE
	- POSTGRESQL\_HOST
	- POSTGRESQL\_PORT
	- POSTGRESQL\_DATABASE\_NAME
	- POSTGRESQL\_KEY\_VALUE\_TABLE\_NAME
	- POSTGRESQL\_SESSION\_INFO\_TABLE\_NAME
	- POSTGRESQL\_EMAILPASSWORD\_USERS\_TABLE\_NAME
	- POSTGRESQL\_EMAILPASSWORD\_PSWD\_RESET\_TOKENS\_TABLE\_NAME
	- POSTGRESQL\_EMAILVERIFICATION\_TOKENS\_TABLE\_NAME
	- POSTGRESQL\_EMAILVERIFICATION\_VERIFIED\_EMAILS\_TABLE\_NAME
	- POSTGRESQL\_THIRDPARTY\_USERS\_TABLE\_NAME
  

```bash
$ docker run \
	-p 3567:3567 \
	-e POSTGRESQL_USER=postgresqlUser \
	-e POSTGRESQL_HOST=192.168.1.2 \
	-e POSTGRESQL_PORT=5432 \
	-e POSTGRESQL_PASSWORD=password \
	-d supertokens/supertokens-postgresql
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
$ docker run \
	-p 3567:3567 \
	-v /path/to/config.yaml:/usr/lib/supertokens/config.yaml \
	-d supertokens/supertokens-postgresql
```

## Logging
- By default, all the logs will be available via the `docker logs <container-name>` command.
- You can setup logging to a shared volume by:
	- Setting the `info_log_path` and `error_log_path` variables in your `config.yaml` file (or passing the values asn env variables).
	- Mounting the shared volume for the logging directory.

```bash
$ docker run \
	-p 3567:3567 \
	-v /path/to/logsFolder:/home/logsFolder \
	-e INFO_LOG_PATH=/home/logsFolder/info.log \
	-e ERROR_LOG_PATH=/home/logsFolder/error.log \
	-e POSTGRESQL_USER=postgresqlUser \
	-e POSTGRESQL_PASSWORD=password \
	-d supertokens/supertokens-postgresql
```

## Database setup
- Before you start this container, make sure to initialize your database.
- You do not need to ensure that the Postgresql database has started before this container is started. During bootup, SuperTokens will wait for ~1 hour for a Postgresql instance to be available.
- If ```POSTGRESQL_USER``` and ```POSTGRESQL_PASSWORD``` are not provided, then SuperTokens will use an in memory database.