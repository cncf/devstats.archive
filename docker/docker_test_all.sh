#!/bin/bash
if [ -z "${PASS}" ]
then
  echo "$0: Set the password via PASS=... $*"
  exit 1
fi

if [ "${FROM}" = "host" ]
then
  echo "Testing deployment from the host"
elif [ "${FROM}" = "container" ]
then
  echo "Testing deployment from the container"
else
  echo "$0: set the deployment type via FROM=host or FROM=container"
  exit 2
fi

oauthfile="/etc/github/oauth"
if [ ! -f "${oauthfile}" ]
then
  echo "Warning: no ${oauthfile} file, setting env variables to skip GitHub API"
  GHA2DB_GHAPISKIP=1
  export GHA2DB_GHAPISKIP
else
  echo "GitHub API credentials found (${oauthfile}), using them"
  GHA2DB_GITHUB_OAUTH="`cat ${oauthfile}`"
  export GHA2DB_GITHUB_OAUTH
fi

./docker/docker_remove_psql.sh
./docker/docker_psql.sh || exit 3
./docker/docker_build.sh || exit 4
if [ "${FROM}" = "host" ]
then
  PG_PASS="${PASS}" PG_PASS_RO="${PASS}" PG_PASS_TEAM="${PASS}" ./docker/docker_deploy_from_host.sh || exit 5
elif [ "${FROM}" = "container" ]
then
  PG_PASS="${PASS}" PG_PASS_RO="${PASS}" PG_PASS_TEAM="${PASS}" ./docker/docker_deploy_from_container.sh || exit 6
fi
PG_PASS="${PASS}" ./docker/docker_display_logs.sh || exit 7
PG_PASS="${PASS}" ./docker/docker_devstats.sh || exit 8
PG_PASS="${PASS}" ./docker/docker_display_logs.sh || exit 9
PG_PASS="${PASS}" ./docker/docker_health.sh || exit 10
echo 'All OK'
