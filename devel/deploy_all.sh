#!/bin/bash
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
function finish {
    rm -f /tmp/deploy.wip 2>/dev/null
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi

# TODO: when CNCF updates artwork to include NATS icon
#ICON=nats
PROJ=nats PROJDB=nats PROJORG=nats-io ORGNAME=NATS PORT=3016 ICON=cncf GA=UA-108085315-21 ./devel/deploy_proj.sh || exit 2
