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

# TODO: ICON=nats - when CNCF updates artwork to include NATS icon.
# OCI has no icon in cncf/artwork at all, so use "-" here
PROJ=kubernetes     PROJDB=gha            PROJREPO="kubernetes/kubernetes"      ORGNAME=Kubernetes  PORT=2999 ICON=kubernetes  GRAFSUFF=k8s            GA="UA-108085315-1"  ./devel/deploy_proj.sh || exit 2
PROJ=prometheus     PROJDB=prometheus     PROJREPO="prometheus/prometheus"      ORGNAME=Prometheus  PORT=3001 ICON=prometheus  GRAFSUFF=prometheus     GA="UA-108085315-3"  ./devel/deploy_proj.sh || exit 3
PROJ=opentracing    PROJDB=opentracing    PROJREPO="opentracing/opentracing-go" ORGNAME=OpenTracing PORT=3002 ICON=opentracing GRAFSUFF=opentracing    GA="UA-108085315-4"  ./devel/deploy_proj.sh || exit 4
PROJ=fluentd        PROJDB=fluentd        PROJREPO="fluent/fluentd"             ORGNAME=Fluentd     PORT=3003 ICON=fluentd     GRAFSUFF=fluentd        GA="UA-108085315-5"  ./devel/deploy_proj.sh || exit 5
PROJ=linkerd        PROJDB=linkerd        PROJREPO="linkerd/linkerd"            ORGNAME=Linkerd     PORT=3004 ICON=linkerd     GRAFSUFF=linkerd        GA="UA-108085315-6"  ./devel/deploy_proj.sh || exit 6
PROJ=grpc           PROJDB=grpc           PROJREPO="grpc/grpc"                  ORGNAME=gRPC        PORT=3005 ICON=grpc        GRAFSUFF=grpc           GA="UA-108085315-7"  ./devel/deploy_proj.sh || exit 7
PROJ=coredns        PROJDB=coredns        PROJREPO="coredns/coredns"            ORGNAME=CoreDNS     PORT=3006 ICON=coredns     GRAFSUFF=coredns        GA="UA-108085315-9"  ./devel/deploy_proj.sh || exit 8
PROJ=containerd     PROJDB=containerd     PROJREPO="containerd/containerd"      ORGNAME=containerd  PORT=3007 ICON=containerd  GRAFSUFF=containerd     GA="UA-108085315-10" ./devel/deploy_proj.sh || exit 9
PROJ=rkt            PROJDB=rkt            PROJREPO="rkt/rkt"                    ORGNAME=rkt         PORT=3008 ICON=rkt         GRAFSUFF=rkt            GA="UA-108085315-11" ./devel/deploy_proj.sh || exit 10
PROJ=cni            PROJDB=cni            PROJREPO="containernetworking/cni"    ORGNAME=CNI         PORT=3009 ICON=cni         GRAFSUFF=cni            GA="UA-108085315-12" ./devel/deploy_proj.sh || exit 11
PROJ=envoy          PROJDB=envoy          PROJREPO="envoyproxy/envoy"           ORGNAME=Envoy       PORT=3010 ICON=envoy       GRAFSUFF=envoy          GA="UA-108085315-13" ./devel/deploy_proj.sh || exit 12
PROJ=jaeger         PROJDB=jaeger         PROJREPO="jaegertracing/jaeger"       ORGNAME=Jaeger      PORT=3011 ICON=jaeger      GRAFSUFF=jaeger         GA="UA-108085315-14" ./devel/deploy_proj.sh || exit 13
PROJ=notary         PROJDB=notary         PROJREPO="theupdateframework/notary"  ORGNAME=Notary      PORT=3012 ICON=notary      GRAFSUFF=notary         GA="UA-108085315-15" ./devel/deploy_proj.sh || exit 14
PROJ=tuf            PROJDB=tuf            PROJREPO="theupdateframework/tuf"     ORGNAME=TUF         PORT=3013 ICON=tuf         GRAFSUFF=tuf            GA="UA-108085315-16" ./devel/deploy_proj.sh || exit 15
PROJ=rook           PROJDB=rook           PROJREPO="rook/rook"                  ORGNAME=Rook        PORT=3014 ICON=rook        GRAFSUFF=rook           GA="UA-108085315-17" ./devel/deploy_proj.sh || exit 16
PROJ=vitess         PROJDB=vitess         PROJREPO="vitessio/vitess"            ORGNAME=Vitess      PORT=3015 ICON=vitess      GRAFSUFF=vitess         GA="UA-108085315-18" ./devel/deploy_proj.sh || exit 17
PROJ=nats           PROJDB=nats           PROJREPO="nats-io/gnatsd"             ORGNAME=NATS        PORT=3016 ICON="-"         GRAFSUFF=nats           GA="UA-108085315-21" ./devel/deploy_proj.sh || exit 18
PROJ=opencontainers PROJDB=opencontainers PROJREPO="opencontainers/runc"        ORGNAME=OCI         PORT=3100 ICON="-"         GRAFSUFF=opencontainers GA="UA-108085315-19" ./devel/deploy_proj.sh || exit 19
PROJ=all            PROJDB=allprj         PROJREPO="not/used"                   ORGNAME="All CNCF"  PORT=3254 ICON=cncf        GRAFSUFF=all            GA="UA-108085315-20" ./devel/deploy_proj.sh || exit 20
if [ "$host" = "cncftest.io" ]
then
  PROJ=cncf         PROJDB=cncf           PROJREPO="cncf/landscape"             ORGNAME=CNCF        PORT=3255 ICON=cncf        GRAFSUFF=cncf           GA="UA-108085315-8" ./devel/deploy_proj.sh || exit 21
fi

CERT=1 WWW=1 ./devel/create_www.sh || exit 22
echo "$0: All deployments finished"
