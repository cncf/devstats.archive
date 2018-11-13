#!/bin/bash
# ARTWORK
# GET=1 (attempt to fetch Postgres database and Grafana database from the test server)
# AGET=1 (attempt to fetch 'All CNCF' Postgres database from the test server)
# INIT=1 (needs PG_PASS_RO, PG_PASS_TEAM, initialize from no postgres database state, creates postgres logs database and users)
# SKIPWWW=1 (skips Apache and SSL cert configuration, final result will be Grafana exposed on the server on its port (for example 3010) via HTTP)
# SKIPVARS=1 (if set it will skip final Postgres vars regeneration)
# CUSTGRAFPATH=1 (set this to use non-standard grafana instalation from ~/grafana.v5/)
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

if [ ! -z "$CUSTGRAFPATH" ]
then
  GRAF_USRSHARE="$HOME/grafana.v5/usr.share.grafana"
  GRAF_VARLIB="$HOME/grafana.v5/var.lib.grafana"
  GRAF_ETC="$HOME/grafana.v5/etc.grafana"
fi

if [ -z "$GRAF_USRSHARE" ]
then
  GRAF_USRSHARE="/usr/share/grafana"
fi
if [ -z "$GRAF_VARLIB" ]
then
  GRAF_VARLIB="/var/lib/grafana"
fi
if [ -z "$GRAF_ETC" ]
then
  GRAF_ETC="/etc/grafana"
fi
export GRAF_USRSHARE
export GRAF_VARLIB
export GRAF_ETC

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

if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi

if [ -z "$ONLYDB" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    alldb=`cat ./devel/all_test_dbs.txt`
  else
    alldb=`cat ./devel/all_prod_dbs.txt`
  fi
else
  alldb=$ONLYDB
fi

LASTDB=""
for db in $alldb
do
  exists=`./devel/db.sh psql -tAc "select 1 from pg_database where datname = '$db'"` || exit 100
  if [ ! "$exists" = "1" ]
  then
    LASTDB=$db
  fi
done
export LASTDB
echo "Last missing DB is $LASTDB"

if [ ! -z "$INIT" ]
then
  ./devel/init_database.sh || exit 1
fi

# OCI has no icon in cncf/artwork at all, so use "-" here
# Use GA="-" to skip GA (google analytics) code
# Use ICON="-" to skip project ICON
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    PROJ=kubernetes     PROJDB=gha            PROJREPO="kubernetes/kubernetes"         ORGNAME=Kubernetes   PORT=2999 ICON=kubernetes   GRAFSUFF=k8s            GA="UA-108085315-1"  ./devel/deploy_proj.sh || exit 2
  elif [ "$proj" = "prometheus" ]
  then
    PROJ=prometheus     PROJDB=prometheus     PROJREPO="prometheus/prometheus"         ORGNAME=Prometheus   PORT=3001 ICON=prometheus   GRAFSUFF=prometheus     GA="UA-108085315-3"  ./devel/deploy_proj.sh || exit 3
  elif [ "$proj" = "opentracing" ]
  then
    PROJ=opentracing    PROJDB=opentracing    PROJREPO="opentracing/opentracing-go"    ORGNAME=OpenTracing  PORT=3002 ICON=opentracing  GRAFSUFF=opentracing    GA="UA-108085315-4"  ./devel/deploy_proj.sh || exit 4
  elif [ "$proj" = "fluentd" ]
  then
    PROJ=fluentd        PROJDB=fluentd        PROJREPO="fluent/fluentd"                ORGNAME=Fluentd      PORT=3003 ICON=fluentd      GRAFSUFF=fluentd        GA="UA-108085315-5"  ./devel/deploy_proj.sh || exit 5
  elif [ "$proj" = "linkerd" ]
  then
    PROJ=linkerd        PROJDB=linkerd        PROJREPO="linkerd/linkerd"               ORGNAME=Linkerd      PORT=3004 ICON=linkerd      GRAFSUFF=linkerd        GA="UA-108085315-6"  ./devel/deploy_proj.sh || exit 6
  elif [ "$proj" = "grpc" ]
  then
    PROJ=grpc           PROJDB=grpc           PROJREPO="grpc/grpc"                     ORGNAME=gRPC         PORT=3005 ICON=grpc         GRAFSUFF=grpc           GA="UA-108085315-7"  ./devel/deploy_proj.sh || exit 7
  elif [ "$proj" = "coredns" ]
  then
    PROJ=coredns        PROJDB=coredns        PROJREPO="coredns/coredns"               ORGNAME=CoreDNS      PORT=3006 ICON=coredns      GRAFSUFF=coredns        GA="UA-108085315-9"  ./devel/deploy_proj.sh || exit 8
  elif [ "$proj" = "containerd" ]
  then
    PROJ=containerd     PROJDB=containerd     PROJREPO="containerd/containerd"         ORGNAME=containerd   PORT=3007 ICON=containerd   GRAFSUFF=containerd     GA="UA-108085315-10" ./devel/deploy_proj.sh || exit 9
  elif [ "$proj" = "rkt" ]
  then
    PROJ=rkt            PROJDB=rkt            PROJREPO="rkt/rkt"                       ORGNAME=rkt          PORT=3008 ICON=rkt          GRAFSUFF=rkt            GA="UA-108085315-11" ./devel/deploy_proj.sh || exit 10
  elif [ "$proj" = "cni" ]
  then
    PROJ=cni            PROJDB=cni            PROJREPO="containernetworking/cni"       ORGNAME=CNI          PORT=3009 ICON=cni          GRAFSUFF=cni            GA="UA-108085315-12" ./devel/deploy_proj.sh || exit 11
  elif [ "$proj" = "envoy" ]
  then
    PROJ=envoy          PROJDB=envoy          PROJREPO="envoyproxy/envoy"              ORGNAME=Envoy        PORT=3010 ICON=envoy        GRAFSUFF=envoy          GA="UA-108085315-13" ./devel/deploy_proj.sh || exit 12
  elif [ "$proj" = "jaeger" ]
  then
    PROJ=jaeger         PROJDB=jaeger         PROJREPO="jaegertracing/jaeger"          ORGNAME=Jaeger       PORT=3011 ICON=jaeger       GRAFSUFF=jaeger         GA="UA-108085315-14" ./devel/deploy_proj.sh || exit 13
  elif [ "$proj" = "notary" ]
  then
    PROJ=notary         PROJDB=notary         PROJREPO="theupdateframework/notary"     ORGNAME=Notary       PORT=3012 ICON=notary       GRAFSUFF=notary         GA="UA-108085315-15" ./devel/deploy_proj.sh || exit 14
  elif [ "$proj" = "tuf" ]
  then
    PROJ=tuf            PROJDB=tuf            PROJREPO="theupdateframework/tuf"        ORGNAME=TUF          PORT=3013 ICON=tuf          GRAFSUFF=tuf            GA="UA-108085315-16" ./devel/deploy_proj.sh || exit 15
  elif [ "$proj" = "rook" ]
  then
    PROJ=rook           PROJDB=rook           PROJREPO="rook/rook"                     ORGNAME=Rook         PORT=3014 ICON=rook         GRAFSUFF=rook           GA="UA-108085315-17" ./devel/deploy_proj.sh || exit 16
  elif [ "$proj" = "vitess" ]
  then
    PROJ=vitess         PROJDB=vitess         PROJREPO="vitessio/vitess"               ORGNAME=Vitess       PORT=3015 ICON=vitess       GRAFSUFF=vitess         GA="UA-108085315-18" ./devel/deploy_proj.sh || exit 17
  elif [ "$proj" = "nats" ]
  then
    PROJ=nats           PROJDB=nats           PROJREPO="nats-io/gnatsd"                ORGNAME=NATS         PORT=3016 ICON=nats         GRAFSUFF=nats           GA="UA-108085315-21" ./devel/deploy_proj.sh || exit 18
  elif [ "$proj" = "opa" ]
  then
    PROJ=opa            PROJDB=opa            PROJREPO="open-policy-agent/opa"         ORGNAME=OPA          PORT=3017 ICON=opa          GRAFSUFF=opa            GA="UA-108085315-22" ./devel/deploy_proj.sh || exit 19
  elif [ "$proj" = "spiffe" ]
  then
    PROJ=spiffe         PROJDB=spiffe         PROJREPO="spiffe/spiffe"                 ORGNAME=SPIFFE       PORT=3018 ICON=spiffe       GRAFSUFF=spiffe         GA="UA-108085315-23" ./devel/deploy_proj.sh || exit 20
  elif [ "$proj" = "spire" ]
  then
    PROJ=spire          PROJDB=spire          PROJREPO="spiffe/spire"                  ORGNAME=SPIRE        PORT=3019 ICON=spire        GRAFSUFF=spire          GA="UA-108085315-24" ./devel/deploy_proj.sh || exit 21
  elif [ "$proj" = "cloudevents" ]
  then
    PROJ=cloudevents    PROJDB=cloudevents    PROJREPO="cloudevents/spec"              ORGNAME=CloudEvents  PORT=3020 ICON=cloudevents  GRAFSUFF=cloudevents    GA="UA-108085315-25" ./devel/deploy_proj.sh || exit 22
  elif [ "$proj" = "telepresence" ]
  then
    PROJ=telepresence   PROJDB=telepresence   PROJREPO="telepresenceio/telepresence"   ORGNAME=Telepresence PORT=3021 ICON=telepresence GRAFSUFF=telepresence   GA="UA-108085315-26" ./devel/deploy_proj.sh || exit 23
  elif [ "$proj" = "helm" ]
  then
    PROJ=helm           PROJDB=helm           PROJREPO="kubernetes/helm"               ORGNAME=Helm         PORT=3022 ICON=helm         GRAFSUFF=helm           GA="UA-108085315-27" ./devel/deploy_proj.sh || exit 24
  elif [ "$proj" = "openmetrics" ]
  then
    PROJ=openmetrics    PROJDB=openmetrics    PROJREPO="OpenObservability/OpenMetrics" ORGNAME=OpenMetrics  PORT=3023 ICON=openmetrics  GRAFSUFF=openmetrics    GA="UA-108085315-28" ./devel/deploy_proj.sh || exit 25
  elif [ "$proj" = "harbor" ]
  then
    PROJ=harbor         PROJDB=harbor         PROJREPO="goharbor/harbor"               ORGNAME=Harbor       PORT=3024 ICON=harbor       GRAFSUFF=harbor         GA="UA-108085315-29" ./devel/deploy_proj.sh || exit 26
# TODO: icons
  elif [ "$proj" = "etcd" ]
  then
    PROJ=etcd           PROJDB=etcd           PROJREPO="etcd-io/etcd"                  ORGNAME=etcd         PORT=3025 ICON=cncf         GRAFSUFF=etcd           GA="UA-108085315-30" ./devel/deploy_proj.sh || exit 27
  elif [ "$proj" = "tikv" ]
  then
    PROJ=tikv           PROJDB=tikv           PROJREPO="tikv/tikv"                     ORGNAME=TiKV         PORT=3026 ICON=tikv         GRAFSUFF=tikv           GA="UA-108085315-31" ./devel/deploy_proj.sh || exit 28
  elif [ "$proj" = "cortex" ]
  then
    PROJ=cortex         PROJDB=cortex         PROJREPO="cortexproject/cortex"          ORGNAME=Cortex       PORT=3027 ICON=cortex       GRAFSUFF=cortex         GA="UA-108085315-32" ./devel/deploy_proj.sh || exit 29
  elif [ "$proj" = "buildpacks" ]
  then
    PROJ=buildpacks     PROJDB=buildpacks     PROJREPO="buildpack/lifecycle"           ORGNAME=Buildpacks   PORT=3028 ICON=buildpacks   GRAFSUFF=buildpacks     GA="UA-108085315-33" ./devel/deploy_proj.sh || exit 30
  elif [ "$proj" = "falco" ]
  then
    PROJ=falco          PROJDB=falco          PROJREPO="falcosecurity/falco"           ORGNAME=Falco        PORT=3029 ICON=falco        GRAFSUFF=falco          GA="UA-108085315-34" ./devel/deploy_proj.sh || exit 31
# TODO: missing dragonfly icons
  elif [ "$proj" = "dragonfly" ]
  then
    PROJ=dragonfly      PROJDB=dragonfly      PROJREPO="alibaba/Dragonfly"             ORGNAME=Dragonfly    PORT=3030 ICON=cncf        GRAFSUFF=dragonfly       GA="UA-108085315-35" ./devel/deploy_proj.sh || exit 39
  elif [ "$proj" = "opencontainers" ]
  then
    PROJ=opencontainers PROJDB=opencontainers PROJREPO="opencontainers/runc"           ORGNAME=OCI          PORT=3100 ICON="-"          GRAFSUFF=opencontainers GA="UA-108085315-19" ./devel/deploy_proj.sh || exit 32
  elif [ "$proj" = "cncf" ]
  then
    PROJ=cncf           PROJDB=cncf           PROJREPO="cncf/landscape"                ORGNAME=CNCF         PORT=3255 ICON=cncf         GRAFSUFF=cncf           GA="UA-108085315-8" ./devel/deploy_proj.sh || exit 33
  elif [ "$proj" = "istio" ]
  then
    PROJ=istio          PROJDB=istio          PROJREPO="istio/istio"                   ORGNAME=Istio        PORT=3101 ICON=cncf         GRAFSUFF=istio          GA="-"              ./devel/deploy_proj.sh || exit 34
  elif [ "$proj" = "spinnaker" ]
  then
    PROJ=spinnaker      PROJDB=spinnaker      PROJREPO="spinnaker/spinnaker"           ORGNAME=Spinnaker    PORT=3102 ICON=cncf         GRAFSUFF=spinnaker      GA="-"              ./devel/deploy_proj.sh || exit 35
  elif [ "$proj" = "all" ]
  then
    PROJ=all            PROJDB=allprj         PROJREPO="not/used"                      ORGNAME="All CNCF"   PORT=3254 ICON=cncf         GRAFSUFF=all            GA="UA-108085315-20" ./devel/deploy_proj.sh || exit 36
  else
    echo "Unknown project: $proj"
    exit 28
  fi
done

if [ -z "$SKIPWWW" ]
then
  CERT=1 WWW=1 ./devel/create_www.sh || exit 37
fi
if [ -z "$SKIPVARS" ]
then
  ./devel/vars_all.sh || exit 38
fi
echo "$0: All deployments finished"
