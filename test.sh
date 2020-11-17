set -e
# build image
docker build -t supertokens-postgresql:circleci .

test_equal () {
    if [[ $1 -ne $2 ]]
    then
        printf "\x1b[1;31merror\x1b[0m in $3\n"
        exit 1
    fi
}

no_of_running_containers () {
    docker ps -q | wc -l
}

test_hello () {
    message=$1
    STATUS_CODE=$(curl -I -X GET http://127.0.0.1:3567/hello -o /dev/null -w '%{http_code}\n' -s)
    if [[ $STATUS_CODE -ne "200" ]]
    then
        printf "\x1b[1;31merror\xd1b[0m in $message\n"
        exit 1
    fi
}

test_session_post () {
    message=$1
    STATUS_CODE=$(curl -X POST http://127.0.0.1:3567/session -H "Content-Type: application/json" -d '{
        "userId": "testing",
        "userDataInJWT": {},
        "userDataInDatabase": {},
        "deviceDriverInfo": {
            "frontendSDK": [{
                "name": "ios",
                "version": "1.0.0"
            }],
            "driver": {
                "name": "node",
                "version": "1.0.0"
            }
        }
    }' -o /dev/null -w '%{http_code}\n' -s)
    if [[ $STATUS_CODE -ne "200" ]]
    then
        printf "\x1b[1;31merror\xd1b[0m in $message\n"
        exit 1
    fi
}

# start postgresql server
docker run -e DISABLE_TELEMETRY=true --rm -d -p 5432:5432 --name postgres -e POSTGRES_PASSWORD=root -e POSTGRES_USER=root postgres

sleep 26s

docker exec -it postgres bash -c "export PGPASSWORD=root && psql -U 'root' -c 'CREATE DATABASE supertokens;'"

# setting network options for testing
OS=`uname`
NETWORK_OPTIONS="-p 3567:3567 -e POSTGRESQL_HOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)"
printf "\npostgresql_host: \"$(ifconfig | grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)\"" >> $PWD/config.yaml

#---------------------------------------------------
# start with no options
docker run -e DISABLE_TELEMETRY=true --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db 

sleep 10s

test_equal `no_of_running_containers` 1 "start with no options"

#---------------------------------------------------
# start with no network options, but in mem db
docker run -e DISABLE_TELEMETRY=true -p 3567:3567 --rm --name supertokens supertokens-postgresql:circleci

sleep 17s

test_equal `no_of_running_containers` 2 "start with no network options, but in mem db"

test_hello "start with no network options, but in mem db"

test_session_post "start with no network options, but in mem db"

docker rm supertokens -f

#---------------------------------------------------
# start with postgresql password
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_PASSWORD=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 10s

test_equal `no_of_running_containers` 1 "start with postgresql password"

#---------------------------------------------------
# start with postgresql user
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_USER=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 10s

test_equal `no_of_running_containers` 1 "start with postgresql user"

#---------------------------------------------------
# start with postgresql user, postgresql password
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_USER=root -e POSTGRESQL_PASSWORD=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` 2 "start with postgresql user, postgresql password"

test_hello "start with postgresql user, postgresql password"

test_session_post "start with postgresql user, postgresql password"

docker rm supertokens -f

#---------------------------------------------------
# start by sharing config.yaml
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -v $PWD/config.yaml:/usr/lib/supertokens/config.yaml --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` 2 "start by sharing config.yaml"

test_hello "start by sharing config.yaml"

test_session_post "start by sharing config.yaml"

docker rm supertokens -f

# ---------------------------------------------------
# test info path
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -v $PWD:/home/supertokens -e POSTGRESQL_USER=root -e POSTGRESQL_PASSWORD=root -e INFO_LOG_PATH=/home/supertokens/info.log -e ERROR_LOG_PATH=/home/supertokens/error.log --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` 2 "test info path"

test_hello "test info path"

test_session_post "test info path"

if [[ ! -f $PWD/info.log || ! -f $PWD/error.log ]]
then
    exit 1
fi

docker rm supertokens -f

rm -rf $PWD/info.log
rm -rf $PWD/error.log
git checkout $PWD/config.yaml

docker rm postgres -f

printf "\x1b[1;32m%s\x1b[0m\n" "success"
exit 0