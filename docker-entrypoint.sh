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

    echo "\n" >> $CONFIG_FILE

    # verify postgresql user name is passed
    if [ ! -z $POSTGRESQL_USER ]
    then
        echo "postgresql_user: \"$POSTGRESQL_USER\"" >> $CONFIG_FILE
    fi

    # verify postgresql password is passed
    if [ ! -z $POSTGRESQL_PASSWORD ]
    then
        echo "postgresql_password: \"$POSTGRESQL_PASSWORD\"" >> $CONFIG_FILE
    fi

    # verify cookie domain is passed
    if [ ! -z $COOKIE_DOMAIN ]
    then
        echo "cookie_domain: $COOKIE_DOMAIN" >> $CONFIG_FILE
    fi

    # verify refresh api path is passed
    if [ ! -z $REFRESH_API_PATH ]
    then
        echo "refresh_api_path: \"$REFRESH_API_PATH\"" >> $CONFIG_FILE
    fi

    # check if supertokens host is passed
    if [ ! -z $SUPERTOKENS_HOST ]
    then
        echo "host: \"$SUPERTOKENS_HOST\"" >> $CONFIG_FILE
    else
        echo "host: 0.0.0.0" >> $CONFIG_FILE
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

    # check if access token path is passed
    if [ ! -z $ACCESS_TOKEN_PATH ]
    then
        echo "access_token_path: \"$ACCESS_TOKEN_PATH\"" >> $CONFIG_FILE
    fi

    # check if access token signing key dynamic is passed
    if [ ! -z $ACCESS_TOKEN_SIGNING_KEY_DYNAMIC ]
    then
        echo "access_token_signing_key_dynamic: $ACCESS_TOKEN_SIGNING_KEY_DYNAMIC" >> $CONFIG_FILE
    fi

    # check if access token signing key update interval is passed
    if [ ! -z $ACCESS_TOKEN_SIGNING_KEY_UPDATE_INTERVAL ]
    then
        echo "access_token_signing_key_update_interval: $ACCESS_TOKEN_SIGNING_KEY_UPDATE_INTERVAL" >> $CONFIG_FILE
    fi

    # check if enable anti csrf is passed
    if [ ! -z $ENABLE_ANTI_CSRF ]
    then
        echo "enable_anti_csrf: $ENABLE_ANTI_CSRF" >> $CONFIG_FILE
    fi

    # check if refresh token validity is passed
    if [ ! -z $REFRESH_TOKEN_VALIDITY ]
    then
        echo "refresh_token_validity: $REFRESH_TOKEN_VALIDITY" >> $CONFIG_FILE
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
        echo "info_log_path: \"$INFO_LOG_PATH\"" >> $CONFIG_FILE
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
        echo "error_log_path: \"$ERROR_LOG_PATH\"" >> $CONFIG_FILE
    else
        echo "error_log_path: null" >> $CONFIG_FILE
    fi

    # check if cookie secure is passed
    if [ ! -z $COOKIE_SECURE ]
    then
        echo "cookie_secure: $COOKIE_SECURE" >> $CONFIG_FILE
    fi

    # check if session expired status code is passed
    if [ ! -z $SESSION_EXPIRED_STATUS_CODE ]
    then
        echo "session_expired_status_code: $SESSION_EXPIRED_STATUS_CODE" >> $CONFIG_FILE
    fi

    # check if cookie same site is passed
    if [ ! -z $COOKIE_SAME_SITE ]
    then
        echo "cookie_same_site: $COOKIE_SAME_SITE" >> $CONFIG_FILE
    fi

    # check if max server pool size is passed
    if [ ! -z $MAX_SERVER_POOL_SIZE ]
    then
        echo "max_server_pool_size: $MAX_SERVER_POOL_SIZE" >> $CONFIG_FILE
    fi

    # check if max server pool size is passed
    if [ ! -z $POSTGRESQL_CONNECTION_POOL_SIZE ]
    then
        echo "postgresql_connection_pool_size: $POSTGRESQL_CONNECTION_POOL_SIZE" >> $CONFIG_FILE
    fi

    # check if postgresql host is passed
    if [ ! -z $POSTGRESQL_HOST ]
    then
        echo "postgresql_host: \"$POSTGRESQL_HOST\"" >> $CONFIG_FILE
    fi

    # check if postgresql port is passed
    if [ ! -z $POSTGRESQL_PORT ]
    then
        echo "postgresql_port: $POSTGRESQL_PORT" >> $CONFIG_FILE
    fi

    # check if postgresql database name is passed
    if [ ! -z $POSTGRESQL_DATABASE_NAME ]
    then
        echo "postgresql_database_name: \"$POSTGRESQL_DATABASE_NAME\"" >> $CONFIG_FILE
    fi

    # check if postgresql key value table name is passed
    if [ ! -z $POSTGRESQL_KEY_VALUE_TABLE_NAME ]
    then
        echo "postgresql_key_value_table_name: \"$POSTGRESQL_KEY_VALUE_TABLE_NAME\"" >> $CONFIG_FILE
    fi

    # check if postgresql session info table name is passed
    if [ ! -z $POSTGRESQL_SESSION_INFO_TABLE_NAME ]
    then
        echo "postgresql_session_info_table_name: \"$POSTGRESQL_SESSION_INFO_TABLE_NAME\"" >> $CONFIG_FILE
    fi

    # check if postgresql past tokens table name is passed
    if [ ! -z $POSTGRESQL_PAST_TOKENS_TABLE_NAME ]
    then
        echo "postgresql_past_tokens_table_name: \"$POSTGRESQL_PAST_TOKENS_TABLE_NAME\"" >> $CONFIG_FILE
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