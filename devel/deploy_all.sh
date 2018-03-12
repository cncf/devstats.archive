#!/bin/bash
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
host=`hostname`
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

# k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opencontainers all cncf
PROJ=kubernetes PROJDB=gha PROJORG=kubernetes ORGNAME=Kubernetes PORT=2999 ICON=kubernetes GRAFSUFF=k8s GA="UA-108085315-1" ./devel/deploy_proj.sh || exit 2
# TODO: ICON=nats - when CNCF updates artwork to include NATS icon.
PROJ=nats PROJDB=nats PROJORG=nats-io ORGNAME=NATS PORT=3016 ICON=cncf GRAFSUFF=nats GA="UA-108085315-21" ./devel/deploy_proj.sh || exit 2
PROJ=all PROJDB=allprj PROJORG=not_used ORGNAME="All CNCF" PORT=3254 ICON=cncf GRAFSUFF=all GA="UA-108085315-20" ./devel/deploy_proj.sh || exit 2
if [ "$host" = "cncftest.io" ]
then
  PROJ=cncf PROJDB=cncf PROJORG=cncf ORGNAME=CNCF PORT=3255 ICON=cncf GRAFSUFF=cncf "GA=UA-108085315-8" ./devel/deploy_proj.sh || exit 2
fi
