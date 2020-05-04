## About this image

The following parameters are required to start the container:
- `dev` / `production` mode
- `config.yaml` environment variables (Configuration)
- License Key file or License Key ID


## `dev` / `production` mode
- The default value of this is `dev`
- This is the same as what the CLI expects. You can learn more about the differences [here](https://supertokens.io/docs/community/cli/start)


## Configuration
You can use your own `config.yaml` file as a shared volume or pass the key-values as environment variables. 

If you do both, only the shared `config.yaml` file will be considered.
  
#### Using environment variable
Available environment variables
- **Core** [[click for more info](https://supertokens.io/docs/community/configuration/core)]
	- COOKIE\_DOMAIN \[**required**\]
	- REFRESH\_API\_PATH \[**required**\]
	- SUPERTOKENS\_HOST
	- SUPERTOKENS\_PORT
	- ACCESS\_TOKEN\_VALIDITY
	- ACCESS\_TOKEN\_BLACKLISTING
	- ACCESS\_TOKEN\_PATH
	- ACCESS\_TOKEN\_SIGNING\_KEY\_DYNAMIC
	- ACCESS\_TOKEN\_SIGNING\_KEY\_UPDATE\_INTERVAL
	- ENABLE\_ANTI\_CSRF
	- REFRESH\_TOKEN\_VALIDITY
	- INFO\_LOG\_PATH
	- ERROR\_LOG\_PATH
	- COOKIE\_SECURE
	- SESSION\_EXPIRED\_STATUS\_CODE
	- COOKIE\_SAME\_SITE
    - MAX\_SERVER\_POOL\_SIZE
- **POSTGRESQL:** [[click for more info](https://supertokens.io/docs/community/configuration/database/postgresql)]	
	- POSTGRESQL\_USER \[**required**\]
	- POSTGRESQL\_PASSWORD \[**required**\]
	- POSTGRESQL\_CONNECTION\_POOL\_SIZE
	- POSTGRESQL\_HOST
	- POSTGRESQL\_PORT
	- POSTGRESQL\_DATABASE\_NAME
	- POSTGRESQL\_KEY\_VALUE\_TABLE\_NAME
	- POSTGRESQL\_SESSION\_INFO\_TABLE\_NAME
	- POSTGRESQL\_PAST\_TOKENS\_TABLE\_NAME
- **License Key**: [See below]
	- LICENSE_KEY_ID
  

```bash
$ docker run \
	-p 3567:3567 \
	-e POSTGRESQL_USER=postgresqlUser \
	-e POSTGRESQL_HOST=localhost \
	-e POSTGRESQL_PORT=5432 \
	-e POSTGRESQL_PASSWORD=password \
	-e COOKIE_DOMAIN=example.com \
	-e REFRESH_API_PATH=/example/refresh \
	-e LICENSE_KEY_ID=yourLicenseKeyID \
	-d supertokens/supertokens-postgresql dev
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
	-e LICENSE_KEY_ID=yourLicenseKeyID \
	-d supertokens/supertokens-postgresql dev
```

## License Key
You can get your license key from your [SuperTokens dashboard](https://supertokens.io/dashboard).


You can either share your `licenseKey` file, or provide the ID as an environment variable. We recommend providing the file since that way you can run the container without giving it internet access.

Please check this [link](https://supertokens.io/docs/community/about-license-keys) to learn more about license keys.

#### Using environment variables
```bash
$ docker run \
	-p 3567:3567 \
	-e POSTGRESQL_USER=postgresqlUser \
	-e POSTGRESQL_PASSWORD=password \
	-e COOKIE_DOMAIN=example.com \
	-e REFRESH_API_PATH=/example/path \
	-e LICENSE_KEY_ID=<your-license-key-id> \
	-d supertokens/supertokens-postgresql production
```

#### Using your `licenseKey` file
```bash
$ docker run \
	-p 3567:3567 \
	-e POSTGRESQL_USER=postgresqlUser \
	-e POSTGRESQL_PASSWORD=password \
	-e COOKIE_DOMAIN=example.com \
	-e REFRESH_API_PATH=/example/path \
	-v /path/to/licenseKey:/usr/lib/supertokens/licenseKey \	
	-d supertokens/supertokens-postgresql dev
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
	-e COOKIE_DOMAIN=example.com \
	-e REFRESH_API_PATH=/example/path \
	-e LICENSE_KEY_ID=yourLicenseKeyId \
	-d supertokens/supertokens-postgresql production
```

## Database setup
- Before you start this container, make sure to [initialize your database](https://supertokens.io/docs/community/getting-started/database-setup/postgresql).
- You do not need to ensure that the Postgresql database has started before this container is started. During bootup, SuperTokens will wait for ~1 hour for a Postgresql instance to be available.


## CLI reference
Please refer to our [documentation](https://supertokens.io/docs/community/cli/overview) for this.