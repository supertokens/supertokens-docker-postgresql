#!/bin/bash
# Expects a releasePassword file to be ./

# get version------------
version=`cat Dockerfile | grep "ARG CORE_VERSION=" | cut -d'=' -f2`

branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
branch_name="(unnamed branch)"     # detached HEAD

branch_name=${branch_name##refs/heads/}

git fetch --prune --prune-tags


# check that current commit has a dev tag and that it is the correct version
# get current commit hash------------
if [ $# -eq 0 ]
then
	commit_hash=`git log --pretty=format:'%H' -n 1`
else
	commit_hash=$1
fi


# check if current commit already has a tag or not------------
currTag=`git tag -l --points-at $commit_hash`

git tag --delete $currTag
git push --delete origin $currTag

git push origin :refs/tags/v$version
git fetch --prune --prune-tags
git tag v$version
git push --tags

password=`cat ./apiPassword`

PLUGIN_VERSION=$(cat Dockerfile | grep "ARG PLUGIN_VERSION=" | cut -d'=' -f2)
CORE_VERSION=$(cat Dockerfile | grep "ARG CORE_VERSION=" | cut -d'=' -f2)
PLUGIN_NAME=$(cat Dockerfile | grep "ARG PLUGIN_NAME=" | cut -d'=' -f2)
response=`curl -s -X GET \
    "https://api.supertokens.io/0/core/latest/check?password=$password&planType=FREE&version=$CORE_VERSION" \
    -H 'api-version: 0'`
core_response=`echo $response | jq .isLatest`
response=`curl -s -X GET \
    "https://api.supertokens.io/0/plugin/latest/check?password=$password&planType=FREE&version=$PLUGIN_VERSION&name=$PLUGIN_NAME" \
    -H 'api-version: 0'`
plugin_response=`echo $response | jq .isLatest`
if [[ $core_response == "true" ]] && [[ $plugin_response == "true" ]]
then
    echo "pushing to mater..."
    if [[ $branch_name == "(unnamed branch)" ]]
    then
        git checkout -b forrelease
        git merge -s ours master
        git checkout master
        git merge forrelease
        git push
        git checkout forrelease
        echo "Done! Please delete this branch"
    else
        git merge -s ours master
        git checkout master
        git merge origin/$branch_name
        git push
        git checkout $branch_name
        echo "Done!"
    fi
fi