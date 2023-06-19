#!/bin/bash
set -eo pipefail
# -e  Exit immediately if a command exits with a non-zero status.
# -o pipefail the return value of a pipeline is the status of the last command
#    to exit with a non-zero status, or zero if no command exited with a non-zero status

CONFIG_HASH=$(head -n 1 /CONFIG_HASH)

ERROR="\x1b[1;31m"
DEFAULT="\x1b[0m"

# logging functions
log() {
    local level="$1"; shift
    local type="$1"; shift
	printf "[$level$type$DEFAULT]: $*\n"
}
error_log() {
	log "$ERROR" "$@" >&2
    exit 1
}

# if command starts with an option, prepend supertokens start
if [ "${1}" = 'dev' -o "${1}" = "production" -o "${1:0:2}" = "--" ]; then
    # set -- supertokens start "$@"
    set -- supertokens start "$@"
    # check if --foreground option is passed or not
    if [[ "$*" != *--foreground* ]]
    then
        set -- "$@" --foreground
    fi
fi

CONFIG_FILE=/usr/lib/supertokens/config.yaml
CONFIG_MD5SUM="$(md5sum /usr/lib/supertokens/config.yaml | awk '{ print $1 }')"

# if files have been shared using shared volumes, make sure the ownership of the
# /usr/lib/supertokens files still remains with supertokens user
chown -R supertokens:supertokens /usr/lib/supertokens/

if [ "$CONFIG_HASH" = "$CONFIG_MD5SUM" ]
then

    echo "" >> $CONFIG_FILE
    echo "host: 0.0.0.0" >> $CONFIG_FILE

    # verify api keys are passed
    if [ ! -z $API_KEYS ]
    then
        echo "api_keys: $API_KEYS" >> $CONFIG_FILE
    fi

    # verify postgresql user name is passed
    if [ ! -z $POSTGRESQL_USER ]
    then
        echo "postgresql_user: $POSTGRESQL_USER" >> $CONFIG_FILE
    fi

    if [ ! -z $POSTGRESQL_PASSWORD_FILE ]
    then
        POSTGRESQL_PASSWORD=$(cat "$POSTGRESQL_PASSWORD_FILE")
        export POSTGRESQL_PASSWORD
    fi

    # verify postgresql password is passed
    if [ ! -z $POSTGRESQL_PASSWORD ]
    then
        echo "postgresql_password: $POSTGRESQL_PASSWORD" >> $CONFIG_FILE
    fi

    # check if supertokens port is passed
    if [ ! -z $SUPERTOKENS_PORT ]
    then
        echo "port: $SUPERTOKENS_PORT" >> $CONFIG_FILE
    fi

    # check if access token validity is passed
    if [ ! -z $ACCESS_TOKEN_VALIDITY ]
    then
        echo "access_token_validity: $ACCESS_TOKEN_VALIDITY" >> $CONFIG_FILE
    fi

    # check if access token blacklisting is passed
    if [ ! -z $ACCESS_TOKEN_BLACKLISTING ]
    then
        echo "access_token_blacklisting: $ACCESS_TOKEN_BLACKLISTING" >> $CONFIG_FILE
    fi

    # check if access token signing key dynamic is passed
    if [ ! -z $ACCESS_TOKEN_SIGNING_KEY_DYNAMIC ]
    then
        echo "access_token_signing_key_dynamic: $ACCESS_TOKEN_SIGNING_KEY_DYNAMIC" >> $CONFIG_FILE
    fi

    # check if access token signing key update interval is passed
    if [ ! -z $ACCESS_TOKEN_DYNAMIC_SIGNING_KEY_UPDATE_INTERVAL ]
    then
        echo "access_token_dynamic_signing_key_update_interval: $ACCESS_TOKEN_DYNAMIC_SIGNING_KEY_UPDATE_INTERVAL" >> $CONFIG_FILE
    fi

    # check if refresh token validity is passed
    if [ ! -z $REFRESH_TOKEN_VALIDITY ]
    then
        echo "refresh_token_validity: $REFRESH_TOKEN_VALIDITY" >> $CONFIG_FILE
    fi

    if [ ! -z $PASSWORD_RESET_TOKEN_LIFETIME ]
    then
        echo "password_reset_token_lifetime: $PASSWORD_RESET_TOKEN_LIFETIME" >> $CONFIG_FILE
    fi

    if [ ! -z $EMAIL_VERIFICATION_TOKEN_LIFETIME ]
    then
        echo "email_verification_token_lifetime: $EMAIL_VERIFICATION_TOKEN_LIFETIME" >> $CONFIG_FILE
    fi

    if [ ! -z $PASSWORDLESS_MAX_CODE_INPUT_ATTEMPTS ]
    then
        echo "passwordless_max_code_input_attempts: $PASSWORDLESS_MAX_CODE_INPUT_ATTEMPTS" >> $CONFIG_FILE
    fi

    if [ ! -z $PASSWORDLESS_CODE_LIFETIME ]
    then
        echo "passwordless_code_lifetime: $PASSWORDLESS_CODE_LIFETIME" >> $CONFIG_FILE
    fi

    if [ ! -z $BASE_PATH ]
    then
        echo "base_path: $BASE_PATH" >> $CONFIG_FILE
    fi

    if [ ! -z $PASSWORD_HASHING_ALG ]
    then
        echo "password_hashing_alg: $PASSWORD_HASHING_ALG" >> $CONFIG_FILE
    fi

    if [ ! -z $ARGON2_ITERATIONS ]
    then
        echo "argon2_iterations: $ARGON2_ITERATIONS" >> $CONFIG_FILE
    fi

    if [ ! -z $ARGON2_MEMORY_KB ]
    then
        echo "argon2_memory_kb: $ARGON2_MEMORY_KB" >> $CONFIG_FILE
    fi

    if [ ! -z $ARGON2_PARALLELISM ]
    then
        echo "argon2_parallelism: $ARGON2_PARALLELISM" >> $CONFIG_FILE
    fi

    if [ ! -z $ARGON2_HASHING_POOL_SIZE ]
    then
        echo "argon2_hashing_pool_size: $ARGON2_HASHING_POOL_SIZE" >> $CONFIG_FILE
    fi

    if [ ! -z $BCRYPT_LOG_ROUNDS ]
    then
        echo "bcrypt_log_rounds: $BCRYPT_LOG_ROUNDS" >> $CONFIG_FILE
    fi

    if [ ! -z $FIREBASE_PASSWORD_HASHING_SIGNER_KEY ]
    then
        echo "firebase_password_hashing_signer_key: $FIREBASE_PASSWORD_HASHING_SIGNER_KEY" >> $CONFIG_FILE
    fi

    if [ ! -z $FIREBASE_PASSWORD_HASHING_POOL_SIZE ]
    then
        echo "firebase_password_hashing_pool_size: $FIREBASE_PASSWORD_HASHING_POOL_SIZE" >> $CONFIG_FILE
    fi

    if [ ! -z $LOG_LEVEL ]
    then
        echo "log_level: $LOG_LEVEL" >> $CONFIG_FILE
    fi

    if [ ! -z $IP_ALLOW_REGEX ]
    then
        echo "ip_allow_regex: $IP_ALLOW_REGEX" >> $CONFIG_FILE
    fi

    if [ ! -z $IP_DENY_REGEX ]
    then
        echo "ip_deny_regex: $IP_DENY_REGEX" >> $CONFIG_FILE
    fi

    if [ ! -z $TOTP_MAX_ATTEMPTS ]
    then
        echo "totp_max_attempts: $TOTP_MAX_ATTEMPTS" >> $CONFIG_FILE
    fi

    if [ ! -z $TOTP_RATE_LIMIT_COOLDOWN_SEC ]
    then
        echo "totp_rate_limit_cooldown_sec: $TOTP_RATE_LIMIT_COOLDOWN_SEC" >> $CONFIG_FILE
    fi

    if [ ! -z $SUPERTOKENS_SAAS_SECRET ]
    then
        echo "supertokens_saas_secret: $SUPERTOKENS_SAAS_SECRET" >> $CONFIG_FILE
    fi

    if [ ! -z $SUPERTOKENS_DEFAULT_CDI_VERSION ]
    then
        echo "supertokens_default_cdi_version: $SUPERTOKENS_DEFAULT_CDI_VERSION" >> $CONFIG_FILE
    fi

    # check if info log path is not passed
    if [ ! -z $INFO_LOG_PATH ]
    then
        if [[ ! -f $INFO_LOG_PATH ]]
        then
            touch $INFO_LOG_PATH
        fi
        # make sure supertokens user has write permission on the file
        chown supertokens:supertokens $INFO_LOG_PATH
        chmod +w $INFO_LOG_PATH
        echo "info_log_path: $INFO_LOG_PATH" >> $CONFIG_FILE
    else
        echo "info_log_path: null" >> $CONFIG_FILE
    fi

    # check if error log path is passed
    if [ ! -z $ERROR_LOG_PATH ]
    then
        if [[ ! -f $ERROR_LOG_PATH ]]
        then
            touch $ERROR_LOG_PATH
        fi
        # make sure supertokens user has write permission on the file
        chown supertokens:supertokens $ERROR_LOG_PATH
        chmod +w $ERROR_LOG_PATH
        echo "error_log_path: $ERROR_LOG_PATH" >> $CONFIG_FILE
    else
        echo "error_log_path: null" >> $CONFIG_FILE
    fi

    # check if max server pool size is passed
    if [ ! -z $MAX_SERVER_POOL_SIZE ]
    then
        echo "max_server_pool_size: $MAX_SERVER_POOL_SIZE" >> $CONFIG_FILE
    fi

    # check if telemetry config is passed
    if [ ! -z $DISABLE_TELEMETRY ]
    then
        echo "disable_telemetry: $DISABLE_TELEMETRY" >> $CONFIG_FILE
    fi

    # check if max server pool size is passed
    if [ ! -z $POSTGRESQL_CONNECTION_POOL_SIZE ]
    then
        echo "postgresql_connection_pool_size: $POSTGRESQL_CONNECTION_POOL_SIZE" >> $CONFIG_FILE
    fi

    # check if postgresql host is passed
    if [ ! -z $POSTGRESQL_HOST ]
    then
        echo "postgresql_host: $POSTGRESQL_HOST" >> $CONFIG_FILE
    fi

    # check if postgresql port is passed
    if [ ! -z $POSTGRESQL_PORT ]
    then
        echo "postgresql_port: $POSTGRESQL_PORT" >> $CONFIG_FILE
    fi

    # check if postgresql database name is passed
    if [ ! -z $POSTGRESQL_DATABASE_NAME ]
    then
        echo "postgresql_database_name: $POSTGRESQL_DATABASE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql table schema is passed
    if [ ! -z $POSTGRESQL_TABLE_SCHEMA ]
    then
        echo "postgresql_table_schema: $POSTGRESQL_TABLE_SCHEMA" >> $CONFIG_FILE
    fi

    # check if postgresql table name prefix is passed
    if [ ! -z $POSTGRESQL_TABLE_NAMES_PREFIX ]
    then
        echo "postgresql_table_names_prefix: $POSTGRESQL_TABLE_NAMES_PREFIX" >> $CONFIG_FILE
    fi

    if [ ! -z $POSTGRESQL_CONNECTION_URI ]
    then
        echo "postgresql_connection_uri: $POSTGRESQL_CONNECTION_URI" >> $CONFIG_FILE
    fi

    # THE CONFIGS BELOW ARE DEPRECATED----------------

    # check if postgresql key value table name is passed
    if [ ! -z $POSTGRESQL_KEY_VALUE_TABLE_NAME ]
    then
        echo "postgresql_key_value_table_name: $POSTGRESQL_KEY_VALUE_TABLE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql session info table name is passed
    if [ ! -z $POSTGRESQL_SESSION_INFO_TABLE_NAME ]
    then
        echo "postgresql_session_info_table_name: $POSTGRESQL_SESSION_INFO_TABLE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql emailpassword user table name is passed
    if [ ! -z $POSTGRESQL_EMAILPASSWORD_USERS_TABLE_NAME ]
    then
        echo "postgresql_emailpassword_users_table_name: $POSTGRESQL_EMAILPASSWORD_USERS_TABLE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql emailpassword password reset table name is passed
    if [ ! -z $POSTGRESQL_EMAILPASSWORD_PSWD_RESET_TOKENS_TABLE_NAME ]
    then
        echo "postgresql_emailpassword_pswd_reset_tokens_table_name: $POSTGRESQL_EMAILPASSWORD_PSWD_RESET_TOKENS_TABLE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql email verification tokens table name is passed
    if [ ! -z $POSTGRESQL_EMAILVERIFICATION_TOKENS_TABLE_NAME ]
    then
        echo "postgresql_emailverification_tokens_table_name: $POSTGRESQL_EMAILVERIFICATION_TOKENS_TABLE_NAME" >> $CONFIG_FILE
    fi

    # check if postgresql verified emails table name is passed
    if [ ! -z $POSTGRESQL_EMAILVERIFICATION_VERIFIED_EMAILS_TABLE_NAME ]
    then
        echo "postgresql_emailverification_verified_emails_table_name: $POSTGRESQL_EMAILVERIFICATION_VERIFIED_EMAILS_TABLE_NAME" >> $CONFIG_FILE
    fi

    if [ ! -z $POSTGRESQL_THIRDPARTY_USERS_TABLE_NAME ]
    then
        echo "postgresql_thirdparty_users_table_name: $POSTGRESQL_THIRDPARTY_USERS_TABLE_NAME" >> $CONFIG_FILE
    fi

fi

# check if no options has been passed to docker run
if [[ "$@" == "supertokens start" ]]
then
    set -- "$@" --foreground
fi

# If container is started as root user, restart as dedicated supertokens user
if [ "$(id -u)" = "0" ] && [ "$1" = 'supertokens' ]; then
    exec gosu supertokens "$@"
else
    exec "$@"
fi
