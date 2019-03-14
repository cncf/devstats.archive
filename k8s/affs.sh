#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_HOST" ] || [ -z "$PG_PORT" ] )
then
  echo "$0: you need to set PG_PASS, PG_HOST and PG_PORT to run this script"
  exit 1
fi

if ( [ -z "$ES_HOST" ] || [ -z "$ES_PORT" ] || [ -z "$ES_PROTO" ] )
then
  echo "$0: you need to set ES_PROTO, ES_HOST and ES_PORT to run this script"
  exit 2
fi

# export GHA2DB_USE_ES
# export GHA2DB_USE_ES_RAW
export GHA2DB_PROJECTS_YAML="k8s/projects.yaml"
export GHA2DB_ES_URL="${ES_PROTO}://${ES_HOST}:${ES_PORT}"
export LIST_FN_PREFIX="k8s/all_"

GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 ./get_repos

. ./devel/all_projs.sh || exit 3
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="gha"
  elif [ "$proj" = "all" ]
  then
    db="allprj"
  fi

  ./devel/check_flag.sh "$db" devstats_running 0 || exit 4
  ./devel/clear_flag.sh "$db" provisioned || exit 5

  if [ -f "./$proj/import_affs.sh" ]
  then
    ./$proj/import_affs.sh || exit 6
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/import_affs.sh || exit 7
  fi
  if [ -f "./$proj/update_affs.sh" ]
  then
    ./$proj/update_affs.sh || exit 8
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/update_affs.sh || exit 9
  fi

  ./devel/set_flag.sh "$db" provisioned || exit 10
done

echo 'All affiliations updated'
