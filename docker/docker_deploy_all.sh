#!/bin/bash
# ARTWORK
# GET=1 (attempt to fetch Postgres database from the test server)
# INIT=1 (needs PG_PASS_RO, PG_PASS_TEAM, initialize from no postgres database state, creates postgres logs database and users)
# SKIPVARS=1 (if set it will skip final Postgres vars regeneration)
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if ( [ ! -z "$INIT" ] && ( [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] ) )
then
  echo "$0: You need to set PG_PASS_RO, PG_PASS_TEAM when using INIT"
  exit 1
fi

if [ -z "$PG_HOST" ]
then
  echo "$0: you need to set PG_HOST to run this script"
  exit 1
fi

if [ -z "$PG_PORT" ]
then
  echo "$0: you need to set PG_PORT to run this script"
  exit 1
fi

# For docker conatiners PG_HOST is 172.17.0.1
export GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml"
export GHA2DB_AFFILIATIONS_JSON="docker/docker_affiliations.json"
export GHA2DB_ES_URL="http://${PG_HOST}:19200"
export GHA2DB_USE_ES=1
export GHA2DB_USE_ES_RAW=1
export LIST_FN_PREFIX="docker/all_"

if [ ! -z "$INIT" ]
then
  ./devel/init_database.sh || exit 1
fi

PROJ=lfn PROJDB=lfn PROJREPO="iovisor/bcc" ORGNAME="Linux Foundation Networking" PORT=3001 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 2

if [ -z "$SKIPVARS" ]
then
  ./devel/vars_all.sh || exit 3
fi
echo "$0: All deployments finished"
