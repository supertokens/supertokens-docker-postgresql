set -e
# build image
docker build -t supertokens-postgresql:circleci .

test_equal () {
    if [[ $1 -ne $2 ]]
    then
        printf "\x1b[1;31merror\x1b[0m from test_equal in $3\n"
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
        printf "\x1b[1;31merror\xd1b[0m from test_hello in $message\n"
        exit 1
    fi
}

test_session_post () {
    message=$1
    STATUS_CODE=$(curl -X POST http://127.0.0.1:3567/recipe/session -H "Content-Type: application/json" -d '{
        "userId": "testing",
        "userDataInJWT": {},
        "userDataInDatabase": {},
        "enableAntiCsrf": true
    }' -o /dev/null -w '%{http_code}\n' -s)
    if [[ $STATUS_CODE -ne "200" ]]
    then
        printf "\x1b[1;31merror\xd1b[0m from test_session_post in $message\n"
        exit 1
    fi
}

test_signup_post () {
    message=$1
    STATUS_CODE=$(curl -X POST http://127.0.0.1:3567/recipe/signup -H "Content-Type: application/json" -d '{
        "email": "testing@testing.test",
        "password": "testpassword"
    }' -o /dev/null -w '%{http_code}\n' -s)
    if [[ $STATUS_CODE -ne "200" ]]
    then
        printf "\x1b[1;31merror\xd1b[0m from test_signup_post in $message\n"
        exit 1
    fi
}

test_signin_post () {
    message=$1
    STATUS_CODE=$(curl -X POST http://127.0.0.1:3567/recipe/signin -H "Content-Type: application/json" -d '{
        "email": "testing@testing.test",
        "password": "testpassword"
    }' -o /dev/null -w '%{http_code}\n' -s)
    if [[ $STATUS_CODE -ne "200" ]]
    then
        printf "\x1b[1;31merror\xd1b[0m from test_signin_post in $message\n"
        exit 1
    fi
}

test_argon2_hash_format () {
  message=$1
  result=$(docker exec -it postgres psql --dbname=supertokens -t -c "select password_hash from emailpassword_users where email = 'testing@testing.test'")
  if [[ "$result" != "$argon2"* ]] # doesn't start with $argon2
    then
      printf "\x1b[1;31merror\xd1b[0m from test_argon2_hash_format in $message\n"
      exit 1
  fi
}

test_not_argon2_hash_format () {
  message=$1
  result=$(docker exec -it postgres psql --dbname=supertokens -t -c "select password_hash from emailpassword_users where email = 'testing@testing.test'")
  if [[ "$result" =~ \$argon2* ]] # starts with $argon2
    then
      printf "\x1b[1;31merror\xd1b[0m from test_not_argon2_hash_format in $message\n"
      exit 1
  fi
}

no_of_containers_running_at_start=`no_of_running_containers`

# start postgresql server
docker run -e DISABLE_TELEMETRY=true --rm -d -p 5432:5432 --name postgres -e POSTGRES_PASSWORD=root -e POSTGRES_USER=root postgres@sha256:5a90725b3751c2c7ac311c9384dfc1a8f6e41823e341fb1dceed96a11677303a

sleep 26s

docker exec -it postgres bash -c "export PGPASSWORD=root && psql -U 'root' -c 'CREATE DATABASE supertokens;'"

# setting network options for testing
OS=`uname`
POSTGRES_IP=$(ip a | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1 | grep -o -E "([0-9]{1,3}\.){3}[0-9]{1,3}")
NETWORK_OPTIONS="-p 3567:3567 -e POSTGRESQL_HOST=$POSTGRES_IP"
NETWORK_OPTIONS_CONNECTION_URI="-p 3567:3567 -e POSTGRESQL_CONNECTION_URI=postgresql://root:root@$POSTGRES_IP:5432"
printf "\npostgresql_host: \"$POSTGRES_IP\"" >> $PWD/config.yaml

#---------------------------------------------------
# start with no options
docker run -e DISABLE_TELEMETRY=true --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 10s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+1)) "start with no options"

#---------------------------------------------------
# start with no network options, but in mem db
docker run -e DISABLE_TELEMETRY=true -p 3567:3567 --rm -d --name supertokens supertokens-postgresql:circleci

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "start with no network options, but in mem db"

test_hello "start with no network options, but in mem db"

test_session_post "start with no network options, but in mem db"

docker rm supertokens -f

#---------------------------------------------------
# start with postgresql password
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_PASSWORD=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 10s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+1)) "start with postgresql password"

#---------------------------------------------------
# start with postgresql user
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_USER=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 10s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+1)) "start with postgresql user"

#---------------------------------------------------
# start with postgresql user, postgresql password
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -e POSTGRESQL_USER=root -e POSTGRESQL_PASSWORD=root --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "start with postgresql user, postgresql password"

test_hello "start with postgresql user, postgresql password"

test_session_post "start with postgresql user, postgresql password"

docker rm supertokens -f

#---------------------------------------------------
# start with postgresql connection uri
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS_CONNECTION_URI --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "start with postgresql connection uri"

test_hello "starstart with postgresql connection uri"

test_session_post "start with postgresql connection uri"

docker rm supertokens -f

#---------------------------------------------------
# start by sharing config.yaml
docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -v $PWD/config.yaml:/usr/lib/supertokens/config.yaml --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "start by sharing config.yaml"

test_hello "start by sharing config.yaml"

test_session_post "start by sharing config.yaml"

docker rm supertokens -f

# ---------------------------------------------------
# test info path

#making sure the user in the container has rights to write to the mounted volume
mkdir $PWD/sthome
chmod a+rw sthome

docker run -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS -v $PWD/sthome/:/home/supertokens -e POSTGRESQL_USER=root -e POSTGRESQL_PASSWORD=root -e INFO_LOG_PATH=/home/supertokens/info.log -e ERROR_LOG_PATH=/home/supertokens/error.log --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "test info path"

test_hello "test info path"

test_session_post "test info path"

if [[ ! -f $PWD/sthome/info.log || ! -f $PWD/sthome/error.log ]]
then
    exit 1
fi

docker rm supertokens -f

git checkout $PWD/config.yaml

#---------------------------------------------------
# test --read-only
docker run  --read-only -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS_CONNECTION_URI --tmpfs=/lib/supertokens/temp/:exec --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "test --read-only"

test_hello "test --read-only"

test_session_post "test --read-only"

test_signup_post "test --read-only"

test_not_argon2_hash_format "test --read-only"

test_signin_post "test --read-only"

docker rm supertokens -f

#---------------------------------------------------
# test --read-only ARGON2
docker run  --read-only -e DISABLE_TELEMETRY=true $NETWORK_OPTIONS_CONNECTION_URI -e PASSWORD_HASHING_ALG=ARGON2  --tmpfs=/lib/supertokens/temp/:exec --rm -d --name supertokens supertokens-postgresql:circleci --no-in-mem-db

sleep 17s

test_equal `no_of_running_containers` $((no_of_containers_running_at_start+2)) "test --read-only ARGON2"

test_hello "test --read-only ARGON2"

test_session_post "test --read-only ARGON2"

test_signup_post "test --read-only ARGON2"

test_argon2_hash_format "test --read-only ARGON2"

test_signin_post "test --read-only ARGON2"

docker rm supertokens -f

docker rm postgres -f

printf "\x1b[1;32m%s\x1b[0m\n" "success"
exit 0