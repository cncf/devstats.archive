#!/bin/bash
# RESTART=1 - reuse existing deployment
if [ -z "${PASS}" ]
then
  echo "$0: Set the password via PASS=... $*"
  exit 1
fi

if [ -z "${GHA2DB_GITHUB_OAUTH}" ]
then
  echo "$0: Set GitHub OAuth token via GHA2DB_GITHUB_OAUTH=... $*"
  exit 2
fi

# Elastic search from witin vagrant

./cron/sysctl_config.sh
if [ -z "${RESTART}" ]
then
  ./docker/docker_remove.sh
fi
./docker/docker_build.sh || exit 3
export ES_HOST=`docker run devstats ip route show 2>/dev/null | awk '/default/ {print $3}'`
export ES_PORT=9200
export ES_URL="http://${ES_HOST}:${ES_PORT}"
host="${ES_HOST}"
./docker/docker_es_wait.sh
PG_PASS="${PASS}" PG_HOST="${host}" ./vagrant/vagrant_psql_wait.sh
PG_PASS="${PASS}" PG_PASS_RO="${PASS}" PG_PASS_TEAM="${PASS}" PG_HOST="${host}" ./vagrant/vagrant_deploy_from_container.sh || exit 4
PG_PASS="${PASS}" PG_HOST="${host}" ./vagrant/vagrant_display_logs.sh || exit 5
PG_PASS="${PASS}" PG_HOST="${host}" ./vagrant/vagrant_devstats.sh || exit 6
PG_PASS="${PASS}" PG_HOST="${host}" ./vagrant/vagrant_display_logs.sh || exit 7
./vagrant/vagrant_es_logs.sh
./docker/docker_es_indexes.sh || exit 8
./docker/docker_es_health.sh || exit 9
PG_PASS="${PASS}" ./vagrant/vagrant_health.sh || exit 10
echo 'All OK'
