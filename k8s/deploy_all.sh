#!/bin/bash
# ARTWORK
# GET=1 (attempt to fetch Postgres database from the test server)
# INIT=1 (needs PG_PASS_RO, PG_PASS_TEAM, initialize from no postgres database state, creates postgres logs database and users)
# ONLYINIT=1 (only run init_database.sh and then exit success)
# SKIPVARS=1 (if set it will skip final Postgres vars regeneration)
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if ( [ ! -z "$INIT" ] && ( [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] ) )
then
  echo "$0: You need to set PG_PASS_RO, PG_PASS_TEAM when using INIT"
  exit 1
fi

if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 2
fi

if [ -z "$ONLYINIT" ]
then
  if ( [ -z "$ES_HOST" ] || [ -z "$ES_PORT" ] || [ -z "$ES_PROTO" ] )
  then
    echo "$0: you need to set ES_PROTO, ES_HOST and ES_PORT to run this script"
    exit 3
  fi

  if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$PROJREPO" ] )
  then
    echo "$0: You need to set PROJ, PROJDB, PROJREPO environment variables to run this script"
    exit 4
  fi
fi

export PG_ADMIN_USER=sa
export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
# export GHA2DB_AFFILIATIONS_JSON="docker/docker_affiliations.json"
# export GHA2DB_AFFILIATIONS_JSON="github_users.json"
# export GHA2DB_USE_ES="${GHA2DB_USE_ES}"
# export GHA2DB_USE_ES_RAW="${GHA2DB_USE_ES_RAW}"
export GHA2DB_USE_ES
export GHA2DB_USE_ES_RAW
export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
export LIST_FN_PREFIX="k8s/all_"
if [ ! -z "$ONLY" ]
then
  export ONLY
fi

if [ ! -z "$INIT" ]
then
  ./devel/init_database.sh || exit 4
  if [ ! -z "$ONLYINIT" ]
  then
    echo "Only init mode, exiting"
    exit 0
  fi
fi

ORGNAME="-" PORT="-" ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 5

if [ -z "$SKIPVARS" ]
then
  GHA2DB_EXCLUDE_VARS="projects_health_partial_html" ./devel/vars_all.sh || exit 6
fi

cat errors.txt 2>/dev/null
echo "<<< errors.txt >>>"

./devel/set_flag.sh "$PROJDB" provisioned || exit 7

echo "$0: All deployments finished"
