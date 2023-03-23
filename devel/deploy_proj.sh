#!/bin/bash
# GET=1 (attempt to fetch Postgres database and Grafana database from the test server)
# AGET=1 (attempt to fetch 'All CNCF' Postgres database from the test server)
# SKIPDBS=1 (entirely skip project's database operations)
# SKIPADDALL=1 (skip adding/merging to allprj)
# SKIPGRAFANA=1 (skip all grafana related stuff)
# WAITBOOT=N (use devel/wait_for_bootstrap.sh script before proceeding to deployment)
# ADD_ALLCDF=1 (add to 'All CDF' instead of 'All CNCF')
# ONLY_GHA - finish after psql.sh part (this allows running for example artificial events backup restore after GHA data is populated)
set -o pipefail
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$PROJREPO" ] || [ -z "$PORT" ] || [ -z "$GA" ] || [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$GRAFSUFF" ] )
then
  echo "$0: You need to set PROJ, PROJDB, PROJREPO, PORT, GA, ICON, ORGNAME, GRAFSUFF environment variables to run this script"
  exit 2
fi
function finish {
    sync_unlock.sh
    rm -f /tmp/deploy.wip 2>/dev/null
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi

echo "$0: $PROJ deploy started"
if [ ! -z "$WAITBOOT" ]
then
  echo "$0: $PROJ wait for bootstrap complete"
  ./devel/wait_for_bootstrap.sh $WAITBOOT || exit 7
  echo "$0: $PROJ wait for bootstrap completed"
fi

if [ -z "$SKIPDBS" ]
then
  PDB=1 TSDB=1 ./devel/create_databases.sh || exit 3
fi

if [ ! -z "$ONLY_GHA" ]
then
  echo "Only GHA data mode, exiting $0"
  exit 0
fi

if [ -z "$ADD_ALLCDF" ]
then
  if ( [ -z "$SKIPADDALL" ] && [ ! "$PROJ" = "all" ] && [ ! "$PROJ" = "opencontainers" ] && \
       [ ! "$PROJ" = "istio" ] && [ ! "$PROJ" = "nodejs" ] && \
       [ ! "$PROJ" = "linux" ] && [ ! "$PROJ" = "zephyr" ] && [ ! "$PROJ" = "contrib" ] && \
       [ ! "$PROJ" = "sam" ] && [ ! "$PROJ" = "azf" ] && [ ! "$PROJ" = "riff" ] && \
       [ ! "$PROJ" = "fn" ] && [ ! "$PROJ" = "openwhisk" ] && [ ! "$PROJ" = "openfaas" ] && \
       [ ! "$PROJ" = "graphql" ] && [ ! "$PROJ" = "graphqljs" ] && [ ! "$PROJ" = "graphiql" ] && \
       [ ! "$PROJ" = "expressgraphql" ] && [ ! "$PROJ" = "graphqlspec" ] && [ ! "$PROJ" = "allcdf" ] && \
       [ ! "$PROJ" = "spinnaker" ] && [ ! "$PROJ" = "tekton" ] && [ ! "$PROJ" = "jenkins" ] && \
       [ ! "$PROJ" = "jenkinsx" ] && [ ! "$PROJ" = "cii" ] && [ ! "$PROJ" = "prestodb" ] && \
       [ ! "$PROJ" = "godotengine" ] && [ ! "$PROJ" = "cdevents" ] && [ ! "$PROJ" = "ortelius" ] && \
       [ ! "$PROJ" = "pyrsia" ] && [ ! "$PROJ" = "screwdrivercd" ] && [ ! "$PROJ" = "shipwright" ] )
  then
    if [ "$PROJDB" = "$LASTDB" ]
    then
      echo "updating ALL CNCF project with reinit mode"
      TSDB=1 ./all/add_project.sh "$PROJDB" "$PROJREPO" || exit 4
    else
      echo "updating ALL CNCF project"
      ./all/add_project.sh "$PROJDB" "$PROJREPO" || exit 5
    fi
  fi
else
  if ( [ -z "$SKIPADDALL" ] && [ ! "$PROJ" = "allcdf" ] )
  then
    if [ "$PROJDB" = "$LASTDB" ]
    then
      echo "updating ALL CDF project with reinit mode"
      TSDB=1 ./allcdf/add_project.sh "$PROJDB" "$PROJREPO" || exit 4
    else
      ./allcdf/add_project.sh "$PROJDB" "$PROJREPO" || exit 5
    fi
  fi
fi

if [ -z "$SKIPGRAFANA" ]
then
  ./devel/create_grafana.sh || exit 6
fi
echo "$0: $PROJ deploy finished"
