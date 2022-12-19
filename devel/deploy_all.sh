#!/bin/bash
# ARTWORK
# GET=1 (attempt to fetch Postgres database and Grafana database from the test server)
# AGET=1 (attempt to fetch 'All CNCF' Postgres database from the test server)
# INIT=1 (needs PG_PASS_RO, PG_PASS_TEAM, initialize from no postgres database state, creates postgres logs database and users)
# SKIPWWW=1 (skips Apache and SSL cert configuration, final result will be Grafana exposed on the server on its port (for example 3010) via HTTP)
# SKIPCERT=1 (skip certificate issue)
# SKIPVARS=1 (if set it will skip final Postgres vars regeneration)
# SKIPICONS=1 (if set it will skip updating all artworks)
# SKIPMAKE=1 (if set it will skip final make install call)
# CUSTGRAFPATH=1 (set this to use non-standard grafana instalation from ~/grafana.v5/)
# SETPASS=1 (should be set on a real first run to set main postgres password interactively, CANNOT be used without user interaction)
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

if [ ! -z "$ONLY" ]
then
  export ONLY
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

. ./devel/all_projs.sh || exit 2

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
  exists=`./devel/db.sh psql postgres -tAc "select 1 from pg_database where datname = '$db'"` || exit 100
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
         PROJ=kubernetes     PROJDB=gha            PROJREPO="kubernetes/kubernetes"           ORGNAME=Kubernetes        PORT=2999 ICON=kubernetes     GRAFSUFF=k8s            GA="UA-108085315-1"  ./devel/deploy_proj.sh || exit 2
  elif [ "$proj" = "prometheus" ]
  then
         PROJ=prometheus     PROJDB=prometheus     PROJREPO="prometheus/prometheus"           ORGNAME=Prometheus        PORT=3001 ICON=prometheus     GRAFSUFF=prometheus     GA="UA-108085315-3"  ./devel/deploy_proj.sh || exit 3
  elif [ "$proj" = "opentracing" ]
  then
         PROJ=opentracing    PROJDB=opentracing    PROJREPO="opentracing/opentracing-go"      ORGNAME=OpenTracing       PORT=3002 ICON=opentracing    GRAFSUFF=opentracing    GA="UA-108085315-4"  ./devel/deploy_proj.sh || exit 4
  elif [ "$proj" = "fluentd" ]
  then
         PROJ=fluentd        PROJDB=fluentd        PROJREPO="fluent/fluentd"                  ORGNAME=Fluentd           PORT=3003 ICON=fluentd        GRAFSUFF=fluentd        GA="UA-108085315-5"  ./devel/deploy_proj.sh || exit 5
  elif [ "$proj" = "linkerd" ]
  then
         PROJ=linkerd        PROJDB=linkerd        PROJREPO="linkerd/linkerd"                 ORGNAME=Linkerd           PORT=3004 ICON=linkerd        GRAFSUFF=linkerd        GA="UA-108085315-6"  ./devel/deploy_proj.sh || exit 6
  elif [ "$proj" = "grpc" ]
  then
         PROJ=grpc           PROJDB=grpc           PROJREPO="grpc/grpc"                       ORGNAME=gRPC              PORT=3005 ICON=grpc           GRAFSUFF=grpc           GA="UA-108085315-7"  ./devel/deploy_proj.sh || exit 7
  elif [ "$proj" = "coredns" ]
  then
         PROJ=coredns        PROJDB=coredns        PROJREPO="coredns/coredns"                 ORGNAME=CoreDNS           PORT=3006 ICON=coredns        GRAFSUFF=coredns        GA="UA-108085315-9"  ./devel/deploy_proj.sh || exit 8
  elif [ "$proj" = "containerd" ]
  then
         PROJ=containerd     PROJDB=containerd     PROJREPO="containerd/containerd"           ORGNAME=containerd        PORT=3007 ICON=containerd     GRAFSUFF=containerd     GA="UA-108085315-10" ./devel/deploy_proj.sh || exit 9
  elif [ "$proj" = "rkt" ]
  then
         PROJ=rkt            PROJDB=rkt            PROJREPO="rkt/rkt"                         ORGNAME=rkt               PORT=3008 ICON=rkt            GRAFSUFF=rkt            GA="UA-108085315-11" ./devel/deploy_proj.sh || exit 10
  elif [ "$proj" = "cni" ]
  then
         PROJ=cni            PROJDB=cni            PROJREPO="containernetworking/cni"         ORGNAME=CNI               PORT=3009 ICON=cni            GRAFSUFF=cni            GA="UA-108085315-12" ./devel/deploy_proj.sh || exit 11
  elif [ "$proj" = "envoy" ]
  then
         PROJ=envoy          PROJDB=envoy          PROJREPO="envoyproxy/envoy"                ORGNAME=Envoy             PORT=3010 ICON=envoy          GRAFSUFF=envoy          GA="UA-108085315-13" ./devel/deploy_proj.sh || exit 12
  elif [ "$proj" = "jaeger" ]
  then
         PROJ=jaeger         PROJDB=jaeger         PROJREPO="jaegertracing/jaeger"            ORGNAME=Jaeger            PORT=3011 ICON=jaeger         GRAFSUFF=jaeger         GA="UA-108085315-14" ./devel/deploy_proj.sh || exit 13
  elif [ "$proj" = "notary" ]
  then
         PROJ=notary         PROJDB=notary         PROJREPO="notaryproject/notation"          ORGNAME=Notary            PORT=3012 ICON=notary         GRAFSUFF=notary         GA="UA-108085315-15" ./devel/deploy_proj.sh || exit 14
  elif [ "$proj" = "tuf" ]
  then
         PROJ=tuf            PROJDB=tuf            PROJREPO="theupdateframework/tuf"          ORGNAME=TUF               PORT=3013 ICON=tuf            GRAFSUFF=tuf            GA="UA-108085315-16" ./devel/deploy_proj.sh || exit 15
  elif [ "$proj" = "rook" ]
  then
         PROJ=rook           PROJDB=rook           PROJREPO="rook/rook"                       ORGNAME=Rook              PORT=3014 ICON=rook           GRAFSUFF=rook           GA="UA-108085315-17" ./devel/deploy_proj.sh || exit 16
  elif [ "$proj" = "vitess" ]
  then
         PROJ=vitess         PROJDB=vitess         PROJREPO="vitessio/vitess"                 ORGNAME=Vitess            PORT=3015 ICON=vitess         GRAFSUFF=vitess         GA="UA-108085315-18" ./devel/deploy_proj.sh || exit 17
  elif [ "$proj" = "nats" ]
  then
         PROJ=nats           PROJDB=nats           PROJREPO="nats-io/nats-server"             ORGNAME=NATS              PORT=3016 ICON=nats           GRAFSUFF=nats           GA="UA-108085315-21" ./devel/deploy_proj.sh || exit 18
  elif [ "$proj" = "opa" ]
  then
         PROJ=opa            PROJDB=opa            PROJREPO="open-policy-agent/opa"           ORGNAME=OPA               PORT=3017 ICON=opa            GRAFSUFF=opa            GA="UA-108085315-22" ./devel/deploy_proj.sh || exit 19
  elif [ "$proj" = "spiffe" ]
  then
         PROJ=spiffe         PROJDB=spiffe         PROJREPO="spiffe/spiffe"                   ORGNAME=SPIFFE            PORT=3018 ICON=spiffe         GRAFSUFF=spiffe         GA="UA-108085315-23" ./devel/deploy_proj.sh || exit 20
  elif [ "$proj" = "spire" ]
  then
         PROJ=spire          PROJDB=spire          PROJREPO="spiffe/spire"                    ORGNAME=SPIRE             PORT=3019 ICON=spire          GRAFSUFF=spire          GA="UA-108085315-24" ./devel/deploy_proj.sh || exit 21
  elif [ "$proj" = "cloudevents" ]
  then
         PROJ=cloudevents    PROJDB=cloudevents    PROJREPO="cloudevents/spec"                ORGNAME=CloudEvents       PORT=3020 ICON=cloudevents    GRAFSUFF=cloudevents    GA="UA-108085315-25" ./devel/deploy_proj.sh || exit 22
  elif [ "$proj" = "telepresence" ]
  then
         PROJ=telepresence   PROJDB=telepresence   PROJREPO="telepresenceio/telepresence"     ORGNAME=Telepresence      PORT=3021 ICON=telepresence   GRAFSUFF=telepresence   GA="UA-108085315-26" ./devel/deploy_proj.sh || exit 23
  elif [ "$proj" = "helm" ]
  then
         PROJ=helm           PROJDB=helm           PROJREPO="helm/helm"                       ORGNAME=Helm              PORT=3022 ICON=helm           GRAFSUFF=helm           GA="UA-108085315-27" ./devel/deploy_proj.sh || exit 24
  elif [ "$proj" = "openmetrics" ]
  then
         PROJ=openmetrics    PROJDB=openmetrics    PROJREPO="OpenObservability/OpenMetrics"   ORGNAME=OpenMetrics       PORT=3023 ICON=openmetrics    GRAFSUFF=openmetrics    GA="UA-108085315-28" ./devel/deploy_proj.sh || exit 25
  elif [ "$proj" = "harbor" ]
  then
         PROJ=harbor         PROJDB=harbor         PROJREPO="goharbor/harbor"                 ORGNAME=Harbor            PORT=3024 ICON=harbor         GRAFSUFF=harbor         GA="UA-108085315-29" ./devel/deploy_proj.sh || exit 26
  elif [ "$proj" = "etcd" ]
  then
         PROJ=etcd           PROJDB=etcd           PROJREPO="etcd-io/etcd"                    ORGNAME=etcd              PORT=3025 ICON=etcd           GRAFSUFF=etcd           GA="UA-108085315-30" ./devel/deploy_proj.sh || exit 27
  elif [ "$proj" = "tikv" ]
  then
         PROJ=tikv           PROJDB=tikv           PROJREPO="tikv/tikv"                       ORGNAME=TiKV              PORT=3026 ICON=tikv           GRAFSUFF=tikv           GA="UA-108085315-31" ./devel/deploy_proj.sh || exit 28
  elif [ "$proj" = "cortex" ]
  then
         PROJ=cortex         PROJDB=cortex         PROJREPO="cortexproject/cortex"            ORGNAME=Cortex            PORT=3027 ICON=cortex         GRAFSUFF=cortex         GA="UA-108085315-32" ./devel/deploy_proj.sh || exit 29
  elif [ "$proj" = "buildpacks" ]
  then
         PROJ=buildpacks     PROJDB=buildpacks     PROJREPO="buildpacks/lifecycle"            ORGNAME=Buildpacks        PORT=3028 ICON=buildpacks     GRAFSUFF=buildpacks     GA="UA-108085315-33" ./devel/deploy_proj.sh || exit 30
  elif [ "$proj" = "falco" ]
  then
         PROJ=falco          PROJDB=falco          PROJREPO="falcosecurity/falco"             ORGNAME=Falco             PORT=3029 ICON=falco          GRAFSUFF=falco          GA="UA-108085315-34" ./devel/deploy_proj.sh || exit 31
  elif [ "$proj" = "dragonfly" ]
  then
         PROJ=dragonfly      PROJDB=dragonfly      PROJREPO="dragonflyoss/Dragonfly"          ORGNAME=Dragonfly         PORT=3030 ICON=dragonfly      GRAFSUFF=dragonfly       GA="UA-108085315-35" ./devel/deploy_proj.sh || exit 39
  elif [ "$proj" = "virtualkubelet" ]
  then 
    PROJ=virtualkubelet      PROJDB=virtualkubelet PROJREPO="virtual-kubelet/virtual-kubelet" ORGNAME="Virtual Kubelet" PORT=3031 ICON=virtualkubelet GRAFSUFF=virtualkubelet GA="UA-108085315-36" ./devel/deploy_proj.sh || exit 40
  elif [ "$proj" = "kubeedge" ]
  then 
    PROJ=kubeedge            PROJDB=kubeedge       PROJREPO="kubeedge/kubeedge"               ORGNAME=KubeEdge          PORT=3032 ICON=kubeedge       GRAFSUFF=kubeedge       GA="UA-108085315-43" ./devel/deploy_proj.sh || exit 43
  elif [ "$proj" = "brigade" ]
  then 
    PROJ=brigade             PROJDB=brigade        PROJREPO="brigadecore/brigade"             ORGNAME=Brigade           PORT=3033 ICON=brigade        GRAFSUFF=brigade        GA="UA-108085315-44" ./devel/deploy_proj.sh || exit 44
  elif [ "$proj" = "crio" ]
  then
    PROJ=crio                PROJDB=crio           PROJREPO="cri-o/cri-o"                     ORGNAME="CRI-O"           PORT=3034 ICON=crio           GRAFSUFF=crio           GA="UA-108085315-45" ./devel/deploy_proj.sh || exit 42
  elif [ "$proj" = "networkservicemesh" ]
  then
    PROJ=networkservicemesh  PROJDB=networkservicemesh PROJREPO="networkservicemesh/networkservicemesh" ORGNAME="Network Service Mesh" PORT=3035 ICON=networkservicemesh GRAFSUFF=networkservicemesh GA="UA-108085315-46" ./devel/deploy_proj.sh || exit 45
  elif [ "$proj" = "openebs" ]
  then
    PROJ=openebs             PROJDB=openebs        PROJREPO="openebs/openebs"                ORGNAME=OpenEBS            PORT=3036 ICON=openebs        GRAFSUFF=openebs        GA="UA-108085315-47" ./devel/deploy_proj.sh || exit 46
  elif [ "$proj" = "opentelemetry" ]
  then
    PROJ=opentelemetry       PROJDB=opentelemetry  PROJREPO="open-telemetry/opentelemetry-java" ORGNAME=OpenTelemetry   PORT=3037 ICON=opentelemetry  GRAFSUFF=opentelemetry  GA="UA-108085315-48" ./devel/deploy_proj.sh || exit 49
  elif [ "$proj" = "thanos" ]
  then
    PROJ=thanos              PROJDB=thanos         PROJREPO="thanos-io/thanos"                ORGNAME=Thanos            PORT=3038 ICON=thanos         GRAFSUFF=thanos         GA="UA-108085315-49" ./devel/deploy_proj.sh || exit 50
  elif [ "$proj" = "flux" ]
  then
    PROJ=flux                PROJDB=flux           PROJREPO="fluxcd/flux2"                    ORGNAME=Flux              PORT=3039 ICON=flux           GRAFSUFF=flux           GA="UA-108085315-50" ./devel/deploy_proj.sh || exit 51
  elif [ "$proj" = "intoto" ]
  then
    PROJ=intoto              PROJDB=intoto         PROJREPO="in-toto/in-toto"                 ORGNAME="in-toto"         PORT=3040 ICON=intoto         GRAFSUFF=intoto         GA="UA-145264316-1"  ./devel/deploy_proj.sh || exit 52
  elif [ "$proj" = "strimzi" ]
  then
    PROJ=strimzi             PROJDB=strimzi        PROJREPO="strimzi/strimzi-kafka-operator"  ORGNAME=Strimzi           PORT=3041 ICON=strimzi        GRAFSUFF=strimzi        GA="UA-145264316-2"  ./devel/deploy_proj.sh || exit 53
  elif [ "$proj" = "kubevirt" ]
  then
    PROJ=kubevirt            PROJDB=kubevirt       PROJREPO="kubevirt/kubevirt"               ORGNAME=KubeVirt          PORT=3042 ICON=kubevirt       GRAFSUFF=kubevirt       GA="UA-145264316-3"  ./devel/deploy_proj.sh || exit 60
  elif [ "$proj" = "longhorn" ]
  then
    PROJ=longhorn            PROJDB=longhorn       PROJREPO="longhorn/longhorn"               ORGNAME=Longhorn          PORT=3043 ICON=longhorn       GRAFSUFF=longhorn       GA="UA-145264316-4"  ./devel/deploy_proj.sh || exit 61
  elif [ "$proj" = "chubaofs" ]
  then
    PROJ=chubaofs            PROJDB=chubaofs       PROJREPO="cubefs/cubefs"                   ORGNAME=CubeFS            PORT=3044 ICON=chubaofs       GRAFSUFF=chubaofs       GA="UA-145264316-5"  ./devel/deploy_proj.sh || exit 62
  elif [ "$proj" = "keda" ]
  then
    PROJ=keda                PROJDB=keda           PROJREPO="kedacore/keda"                   ORGNAME=KEDA              PORT=3045 ICON=keda           GRAFSUFF=keda           GA="UA-145264316-6"  ./devel/deploy_proj.sh || exit 63
  elif [ "$proj" = "smi" ]
  then
    PROJ=smi                 PROJDB=smi            PROJREPO="servicemeshinterface/smi-spec"   ORGNAME=SMI               PORT=3046 ICON=smi            GRAFSUFF=smi            GA="UA-145264316-7"  ./devel/deploy_proj.sh || exit 64
  elif [ "$proj" = "argo" ]
  then
    PROJ=argo                PROJDB=argo           PROJREPO="argoproj/argo"                   ORGNAME=Argo              PORT=3047 ICON=argo           GRAFSUFF=argo           GA="UA-145264316-8"  ./devel/deploy_proj.sh || exit 65
  elif [ "$proj" = "volcano" ]
  then
    PROJ=volcano             PROJDB=volcano        PROJREPO="volcano-sh/volcano"              ORGNAME=Volcano           PORT=3048 ICON=volcano        GRAFSUFF=volcano        GA="UA-145264316-9"  ./devel/deploy_proj.sh || exit 66
  elif [ "$proj" = "cnigenie" ]
  then
    PROJ=cnigenie           PROJDB=cnigenie        PROJREPO="cni-genie/CNI-Genie"             ORGNAME="CNI-Genie"       PORT=3049 ICON=cnigenie       GRAFSUFF=cnigenie       GA="UA-145264316-10" ./devel/deploy_proj.sh || exit 67
  elif [ "$proj" = "keptn" ]
  then
    PROJ=keptn              PROJDB=keptn           PROJREPO="keptn/keptn"                     ORGNAME=Keptn             PORT=3050 ICON=keptn          GRAFSUFF=keptn          GA="UA-145264316-11" ./devel/deploy_proj.sh || exit 68
  elif [ "$proj" = "kudo" ]
  then
    PROJ=kudo               PROJDB=kudo            PROJREPO="kudobuilder/kudo"                ORGNAME=Kudo              PORT=3051 ICON=kudo           GRAFSUFF=kudo           GA="UA-145264316-12" ./devel/deploy_proj.sh || exit 69
  elif [ "$proj" = "cloudcustodian" ]
  then
    PROJ=cloudcustodian     PROJDB=cloudcustodian  PROJREPO="cloud-custodian/cloud-custodian" ORGNAME="Cloud Custodian" PORT=3052 ICON=cloudcustodian GRAFSUFF=cloudcustodian GA="UA-145264316-13" ./devel/deploy_proj.sh || exit 70
  elif [ "$proj" = "dex" ]
  then
    PROJ=dex                PROJDB=dex             PROJREPO="dexidp/dex"                      ORGNAME=Dex               PORT=3053 ICON=dex            GRAFSUFF= dex           GA="UA-145264316-14" ./devel/deploy_proj.sh || exit 71
  elif [ "$proj" = "litmuschaos" ]
  then
    PROJ=litmuschaos        PROJDB=litmuschaos     PROJREPO="litmuschaos/litmus"              ORGNAME=LitmusChaos       PORT=3054 ICON=litmuschaos    GRAFSUFF=litmuschaos    GA="UA-145264316-15" ./devel/deploy_proj.sh || exit 72
  elif [ "$proj" = "artifacthub" ]
  then
    PROJ=artifacthub        PROJDB=artifacthub     PROJREPO="artifacthub/hub"                 ORGNAME="Artifact Hub"    PORT=3055 ICON=artifacthub    GRAFSUFF=artifacthub    GA="UA-145264316-16" ./devel/deploy_proj.sh || exit 73
  elif [ "$proj" = "kuma" ]
  then
    PROJ=kuma               PROJDB=kuma            PROJREPO="kumahq/kuma"                     ORGNAME=Kuma              PORT=3056 ICON=kuma           GRAFSUFF=kuma           GA="UA-145264316-17" ./devel/deploy_proj.sh || exit 74
  elif [ "$proj" = "parsec" ]
  then
    PROJ=parsec             PROJDB=parsec          PROJREPO="parallaxsecond/parsec"           ORGNAME=PARSEC            PORT=3057 ICON=parsec         GRAFSUFF=parsec         GA="UA-145264316-18" ./devel/deploy_proj.sh || exit 75
  elif [ "$proj" = "bfe" ]
  then
    PROJ=bfe                PROJDB=bfe             PROJREPO="bfenetworks/bfe"                 ORGNAME=BFE               PORT=3058 ICON=bfe            GRAFSUFF=bfe            GA="UA-145264316-19" ./devel/deploy_proj.sh || exit 76
  elif [ "$proj" = "crossplane" ]
  then
    PROJ=crossplane         PROJDB=crossplane      PROJREPO="crossplane/crossplane"           ORGNAME=Crossplane        PORT=3059 ICON=crossplane     GRAFSUFF=crossplane     GA="UA-145264316-20" ./devel/deploy_proj.sh || exit 77
  elif [ "$proj" = "contour" ]
  then
    PROJ=contour            PROJDB=contour         PROJREPO="projectcontour/contour"          ORGNAME=Contour           PORT=3060 ICON=contour        GRAFSUFF=contour        GA="UA-145264316-21" ./devel/deploy_proj.sh || exit 78
  elif [ "$proj" = "operatorframework" ]
  then
    PROJ=operatorframework  PROJDB=operatorframework PROJREPO="operator-framework/operator-sdk" ORGNAME=Operator Framework PORT=3061 ICON=operatorframework GRAFSUFF=operatorframework GA="UA-145264316-22" ./devel/deploy_proj.sh || exit 79
  elif [ "$proj" = "chaosmesh" ]
  then
    PROJ=chaosmesh          PROJDB=chaosmesh       PROJREPO="chaos-mesh/chaos-mesh"           ORGNAME="Chaos Mesh"      PORT=3062 ICON=chaosmesh      GRAFSUFF=chaosmesh      GA="UA-145264316-23" ./devel/deploy_proj.sh || exit 80
  elif [ "$proj" = "serverlessworkflow" ]
  then
    PROJ=serverlessworkflow PROJDB=serverlessworkflow PROJREPO="serverlessworkflow/specification" ORGNAME="Serverless Workflow" PORT=3063 ICON=serverlessworkflow GRAFSUFF=serverlessworkflow GA="UA-145264316-24" ./devel/deploy_proj.sh || exit 81
  elif [ "$proj" = "k3s" ]
  then
    PROJ=k3s                 PROJDB=k3s            PROJREPO="k3s-io/k3s"                      ORGNAME=K3s               PORT=3064 ICON=k3s            GRAFSUFF=k3s            GA="UA-145264316-25" ./devel/deploy_proj.sh || exit 82
  elif [ "$proj" = "backstage" ]
  then
    PROJ=backstage           PROJDB=backstage      PROJREPO="backstage/backstag"              ORGNAME=Backstage         PORT=3065 ICON=backstage      GRAFSUFF=backstage      GA="UA-145264316-26" ./devel/deploy_proj.sh || exit 83
  elif [ "$proj" = "tremor" ]
  then
    PROJ=tremor              PROJDB=tremor         PROJREPO="tremor-rs/tremor-runtime"        ORGNAME=tremor            PORT=3066 ICON=tremor         GRAFSUFF=tremor         GA="UA-145264316-27" ./devel/deploy_proj.sh || exit 84
  elif [ "$proj" = "metal3" ]
  then
    PROJ=metal3              PROJDB=metal3         PROJREPO="metal3-io/cluster-api-provider-metal3" ORGNAME="Metal³"    PORT=3067 ICON=metal3         GRAFSUFF=metal3         GA="UA-145264316-28" ./devel/deploy_proj.sh || exit 85
  elif [ "$proj" = "porter" ]
  then
    PROJ=porter              PROJDB=porter         PROJREPO="getporter/porter"                ORGNAME=Porter            PORT=3068 ICON=porter         GRAFSUFF=porter         GA="UA-145264316-29" ./devel/deploy_proj.sh || exit 86
  elif [ "$proj" = "openyurt" ]
  then
    PROJ=openyurt            PROJDB=openyurt       PROJREPO="openyurtio/openyurt"             ORGNAME=OpenYurt          PORT=3069 ICON=openyurt       GRAFSUFF=openyurt       GA="UA-145264316-30" ./devel/deploy_proj.sh || exit 87
  elif [ "$proj" = "openservicemesh" ]
  then
    PROJ=openservicemesh     PROJDB=openservicemesh PROJREPO="openservicemesh/osm"            ORGNAME="Open Service Mesh" PORT=3070 ICON=openservicemesh GRAFSUFF=openservicemesh GA="UA-145264316-31" ./devel/deploy_proj.sh || exit 88
  elif [ "$proj" = "keylime" ]
  then
    PROJ=keylime             PROJDB=keylime        PROJREPO="keylime/keylime"                 ORGNAME=Keylime           PORT=3071 ICON=keylime        GRAFSUFF=keylime        GA="UA-145264316-32" ./devel/deploy_proj.sh || exit 89
  elif [ "$proj" = "schemahero" ]
  then
    PROJ=schemahero          PROJDB=schemahero     PROJREPO="schemahero/schemahero"           ORGNAME=SchemaHero        PORT=3072 ICON=schemahero     GRAFSUFF=schemahero     GA="UA-145264316-33" ./devel/deploy_proj.sh || exit 91
  elif [ "$proj" = "cdk8s" ]
  then
    PROJ=cdk8s               PROJDB=cdk8s          PROJREPO="cdk8s-team/cdk8s" ORGNAME="Cloud Deployment Kit for Kubernetes" PORT=3073 ICON=cdk8s     GRAFSUFF=cdk8s          GA="UA-145264316-34" ./devel/deploy_proj.sh || exit 92
  elif [ "$proj" = "certmanager" ]
  then
    PROJ=certmanager         PROJDB=certmanager    PROJREPO="cert-manager/cert-manager"       ORGNAME="cert-manager"    PORT=3074 ICON=certmanager    GRAFSUFF=certmanager    GA="UA-145264316-35" ./devel/deploy_proj.sh || exit 93
  elif [ "$proj" = "openkruise" ]
  then
    PROJ=openkruise          PROJDB=openkruise     PROJREPO="openkruise/kruise"               ORGNAME=OpenKruise        PORT=3075 ICON=openkruise     GRAFSUFF=openkruise     GA="UA-145264316-36" ./devel/deploy_proj.sh || exit 94
  elif [ "$proj" = "tinkerbell" ]
  then
    PROJ=tinkerbell          PROJDB=tinkerbell     PROJREPO="tinkerbell/tink"                 ORGNAME=Tinkerbell        PORT=3076 ICON=tinkerbell     GRAFSUFF=tinkerbell     GA="UA-145264316-37" ./devel/deploy_proj.sh || exit 95
  elif [ "$proj" = "pravega" ]
  then
    PROJ=pravega             PROJDB=pravega        PROJREPO="pravega/pravega"                 ORGNAME=Pravega           PORT=3077 ICON=pravega        GRAFSUFF=pravega        GA="UA-145264316-38" ./devel/deploy_proj.sh || exit 96
  elif [ "$proj" = "kyverno" ]
  then
    PROJ=kyverno             PROJDB=kyverno        PROJREPO="kyverno/kyverno"                 ORGNAME=Kyverno           PORT=3078 ICON=kyverno        GRAFSUFF=kyverno        GA="UA-145264316-39" ./devel/deploy_proj.sh || exit 97
  elif [ "$proj" = "gitopswg" ]
  then
    PROJ=gitopswg            PROJDB=gitopswg       PROJREPO="gitops-working-group/gitops-working-group" ORGNAME="GitOps WG" PORT=3079 ICON=gitopswg   GRAFSUFF=gitopswg       GA="UA-145264316-40" ./devel/deploy_proj.sh || exit 98
  elif [ "$proj" = "piraeus" ]
  then
    PROJ=piraeus             PROJDB=piraeus        PROJREPO="piraeusdatastore/piraeus-operator" ORGNAME=Piraeus-Datastore PORT=3080 ICON=piraeus      GRAFSUFF=piraeus        GA="UA-145264316-41" ./devel/deploy_proj.sh || exit 99
  elif [ "$proj" = "k8dash" ]
  then
    PROJ=k8dash              PROJDB=k8dash         PROJREPO="skooner-k8s/skooner"             ORGNAME=Skooner           PORT=3081 ICON=k8dash         GRAFSUFF=k8dash         GA="UA-145264316-42" ./devel/deploy_proj.sh || exit 100
  elif [ "$proj" = "athenz" ]
  then
    PROJ=athenz              PROJDB=athenz         PROJREPO="AthenZ/athenz"                   ORGNAME=Athenz            PORT=3082 ICON=athenz         GRAFSUFF=athenz         GA="UA-145264316-43" ./devel/deploy_proj.sh || exit 101
  elif [ "$proj" = "kubeovn" ]
  then
    PROJ=kubeovn             PROJDB=kubeovn        PROJREPO="kubeovn/kube-ovn"                ORGNAME=Kube-OVN          PORT=3083 ICON=kubeovn        GRAFSUFF=kubeovn        GA="UA-145264316-44" ./devel/deploy_proj.sh || exit 102
  elif [ "$proj" = "curiefense" ]
  then
    PROJ=curiefense          PROJDB=curiefense     PROJREPO="curiefense/curiefense"           ORGNAME=Curiefense        PORT=3084 ICON=curiefense     GRAFSUFF=curiefense     GA="UA-145264316-45" ./devel/deploy_proj.sh || exit 103
  elif [ "$proj" = "distribution" ]
  then
    PROJ=distribution        PROJDB=distribution   PROJREPO="distribution/distribution"       ORGNAME=Distribution      PORT=3085 ICON=distribution   GRAFSUFF=distribution   GA="UA-145264316-46" ./devel/deploy_proj.sh || exit 104
  elif [ "$proj" = "ingraind" ]
  then
    PROJ=ingraind            PROJDB=ingraind       PROJREPO="foniod/foniod"                   ORGNAME=Foniod            PORT=3086 ICON=ingraind       GRAFSUFF=ingraind       GA="UA-145264316-47" ./devel/deploy_proj.sh || exit 105
  elif [ "$proj" = "kuberhealthy" ]
  then
    PROJ=kuberhealthy        PROJDB=kuberhealthy   PROJREPO="kuberhealthy/kuberhealthy"       ORGNAME=Kuberhealthy      PORT=3087 ICON=kuberhealthy   GRAFSUFF=kuberhealthy   GA="UA-145264316-48" ./devel/deploy_proj.sh || exit 106
  elif [ "$proj" = "k8gb" ]
  then
    PROJ=k8gb                PROJDB=k8gb           PROJREPO="k8gb-io/k8gb"                    ORGNAME=K8GB              PORT=3088 ICON=k8gb           GRAFSUFF=k8gb           GA="UA-145264316-49" ./devel/deploy_proj.sh || exit 107
  elif [ "$proj" = "trickster" ]
  then
    PROJ=trickster           PROJDB=trickster      PROJREPO="trickstercache/trickster"        ORGNAME=Trickster         PORT=3089 ICON=trickster      GRAFSUFF=trickster      GA="UA-145264316-50" ./devel/deploy_proj.sh || exit 108
  elif [ "$proj" = "emissaryingress" ]
  then
    PROJ=emissaryingress     PROJDB=emissaryingress PROJREPO="emissary-ingress/emissary"      ORGNAME=Emissary-ingress  PORT=3090 ICON=emissaryingress GRAFSUFF=emissaryingress GA="UA-145264316-51" ./devel/deploy_proj.sh || exit 109
  elif [ "$proj" = "wasmedge" ]
  then
    PROJ=wasmedge            PROJDB=wasmedge        PROJREPO="WasmEdge/WasmEdge"              ORGNAME='WasmEdge Runtime' PORT=3091 ICON=wasmedge      GRAFSUFF=wasmedge       GA="UA-145264316-52" ./devel/deploy_proj.sh || exit 110
  elif [ "$proj" = "chaosblade" ]
  then
    PROJ=chaosblade          PROJDB=chaosblade      PROJREPO="chaosblade-io/chaosblade"       ORGNAME=ChaosBlade        PORT=3092 ICON=chaosblade     GRAFSUFF=chaosblade     GA="UA-145264316-53" ./devel/deploy_proj.sh || exit 111
  elif [ "$proj" = "vineyard" ]
  then
    PROJ=vineyard            PROJDB=vineyard        PROJREPO="v6d-io/v6d"                     ORGNAME=Vineyard          PORT=3093 ICON=vineyard       GRAFSUFF=vineyard       GA="UA-145264316-54" ./devel/deploy_proj.sh || exit 112
  elif [ "$proj" = "antrea" ]
  then
    PROJ=antrea              PROJDB=antrea          PROJREPO="antrea-io/antrea"               ORGNAME=Antrea            PORT=3094 ICON=antrea         GRAFSUFF=antrea         GA="UA-145264316-55" ./devel/deploy_proj.sh || exit 113
  elif [ "$proj" = "fluid" ]
  then
    PROJ=fluid               PROJDB=fluid           PROJREPO="fluid-cloudnative/fluid"        ORGNAME=Fluid             PORT=3095 ICON=fluid          GRAFSUFF=fluid          GA="UA-145264316-56" ./devel/deploy_proj.sh || exit 114
  elif [ "$proj" = "submariner" ]
  then
    PROJ=submariner          PROJDB=submariner      PROJREPO="submariner-io/submariner"       ORGNAME=Submariner        PORT=3096 ICON=submariner     GRAFSUFF=submariner     GA="UA-145264316-57" ./devel/deploy_proj.sh || exit 115
  elif [ "$proj" = "pixie" ]
  then
    PROJ=pixie               PROJDB=pixie           PROJREPO="pixie-io/pixie"                 ORGNAME=Pixie             PORT=3097 ICON=pixie          GRAFSUFF=pixie          GA="UA-145264316-58" ./devel/deploy_proj.sh || exit 116
  elif [ "$proj" = "meshery" ]
  then
    PROJ=meshery             PROJDB=meshery         PROJREPO="meshery/meshery"                ORGNAME=Meshery           PORT=3098 ICON=meshery        GRAFSUFF=meshery        GA="UA-145264316-59" ./devel/deploy_proj.sh || exit 117
  elif [ "$proj" = "servicemeshperformance" ]
  then
    PROJ=servicemeshperformance PROJDB=servicemeshperformance PROJREPO="service-mesh-performance/service-mesh-performance" ORGNAME='Service Mesh Performance' PORT=3099 ICON=servicemeshperformance GRAFSUFF=servicemeshperformance GA="UA-145264316-60" ./devel/deploy_proj.sh || exit 118
  elif [ "$proj" = "kubevela" ]
  then
    PROJ=kubevela            PROJDB=kubevela        PROJREPO="kubevela/kubevela"              ORGNAME=KubeVela          PORT=3100 ICON=kubevela       GRAFSUFF=kubevela       GA="UA-145264316-61" ./devel/deploy_proj.sh || exit 119
  elif [ "$proj" = "kubevip" ]
  then
    PROJ=kubevip             PROJDB=kubevip         PROJREPO="kube-vip/kube-vip"              ORGNAME=kube-vip          PORT=3101 ICON=kubevip        GRAFSUFF=kubevip        GA="UA-145264316-62" ./devel/deploy_proj.sh || exit 120
  elif [ "$proj" = "kubedl" ]
  then
    PROJ=kubedl              PROJDB=kubedl          PROJREPO="kubedl-io/kubedl"               ORGNAME=KubeDL            PORT=3102 ICON=kubedl         GRAFSUFF=kubedl         GA="UA-145264316-63" ./devel/deploy_proj.sh || exit 121
  elif [ "$proj" = "krustlet" ]
  then
    PROJ=krustlet            PROJDB=krustlet        PROJREPO="krustlet/krustlet"              ORGNAME=Krustlet          PORT=3103 ICON=krustlet       GRAFSUFF=krustlet       GA="UA-145264316-64" ./devel/deploy_proj.sh || exit 122
  elif [ "$proj" = "krator" ]
  then
    PROJ=krator              PROJDB=krator          PROJREPO="krator-rs/krator"               ORGNAME=Krator            PORT=3104 ICON=krator         GRAFSUFF=krator         GA="UA-145264316-65" ./devel/deploy_proj.sh || exit 123
  elif [ "$proj" = "oras" ]
  then
    PROJ=oras                PROJDB=oras            PROJREPO="oras-project/oras"              ORGNAME=ORAS              PORT=3105 ICON=oras           GRAFSUFF=oras           GA="UA-145264316-66" ./devel/deploy_proj.sh || exit 124
  elif [ "$proj" = "wasmcloud" ]
  then
    PROJ=wasmcloud           PROJDB=wasmcloud       PROJREPO="wasmCloud/wasmCloud"            ORGNAME=wasmCloud         PORT=3106 ICON=wasmcloud      GRAFSUFF=wasmcloud      GA="UA-145264316-67" ./devel/deploy_proj.sh || exit 125
  elif [ "$proj" = "akri" ]
  then
    PROJ=akri                PROJDB=Akri            PROJREPO="project-akri/akri"              ORGNAME=Akri              PORT=3107 ICON=akri           GRAFSUFF=akri           GA="UA-145264316-68" ./devel/deploy_proj.sh || exit 126
  elif [ "$proj" = "metallb" ]
  then
    PROJ=metallb             PROJDB=metallb         PROJREPO="metallb/metallb"                ORGNAME=MetalLB           PORT=3108 ICON=metallb        GRAFSUFF=metallb        GA="UA-145264316-69" ./devel/deploy_proj.sh || exit 127
  elif [ "$proj" = "karmada" ]
  then
    PROJ=karmada             PROJDB=karmada         PROJREPO="karmada-io/karmada"             ORGNAME=Karmada           PORT=3109 ICON=karmada        GRAFSUFF=karmada        GA="UA-145264316-70" ./devel/deploy_proj.sh || exit 128
  elif [ "$proj" = "inclavarecontainers" ]
  then
    PROJ=inclavarecontainers PROJDB=inclavarecontainers PROJREPO="inclavare-containers/inclavare-containers" ORGNAME="Inclavare Containers" PORT=3110 ICON=inclavarecontainers GRAFSUFF=inclavarecontainers GA="UA-145264316-71" ./devel/deploy_proj.sh || exit 129
  elif [ "$proj" = "superedge" ]
  then
    PROJ=superedge           PROJDB=superedge      PROJREPO="superedge/superedge"             ORGNAME=SuperEdge         PORT=3111 ICON=superedge      GRAFSUFF=superedge      GA="UA-145264316-72" ./devel/deploy_proj.sh || exit 130
  elif [ "$proj" = "cilium" ]
  then
    PROJ=cilium              PROJDB=cilium         PROJREPO="cilium/cilium"                   ORGNAME=Cilium            PORT=3112 ICON=cilium         GRAFSUFF=cilium         GA="UA-145264316-73" ./devel/deploy_proj.sh || exit 131
  elif [ "$proj" = "dapr" ]
  then
    PROJ=dapr                PROJDB=dapr           PROJREPO="dapr/dapr"                       ORGNAME=Dapr              PORT=3113 ICON=dapr           GRAFSUFF=dapr           GA="UA-145264316-74" ./devel/deploy_proj.sh || exit 132
  elif [ "$proj" = "openelb" ]
  then
    PROJ=openelb             PROJDB=openelb        PROJREPO="kubesphere/openelb"              ORGNAME=OpenELB           PORT=3114 ICON=openelb        GRAFSUFF=openelb        GA="UA-145264316-75" ./devel/deploy_proj.sh || exit 133
  elif [ "$proj" = "openclustermanagement" ]
  then
    PROJ=openclustermanagement PROJDB=openclustermanagement PROJREPO="open-cluster-management-io/api" ORGNAME="Open Cluster Management" PORT=3115 ICON=openclustermanagement GRAFSUFF=openclustermanagement GA="UA-145264316-76" ./devel/deploy_proj.sh || exit 134
  elif [ "$proj" = "vscodek8stools" ]
  then
    PROJ=vscodek8stools      PROJDB=vscodek8stools PROJREPO="vscode-kubernetes-tools/vscode-kubernetes-tools" ORGNAME="VS Code Kubernetes Tools" PORT=3116 ICON=vscodek8stools GRAFSUFF=vscodek8stools GA="UA-145264316-77" ./devel/deploy_proj.sh || exit 135
  elif [ "$proj" = "nocalhost" ]
  then
    PROJ=nocalhost           PROJDB=nocalhost      PROJREPO="nocalhost/nocalhost"             ORGNAME=Nocalhost         PORT=3117 ICON=nocalhost      GRAFSUFF=nocalhost      GA="UA-145264316-78" ./devel/deploy_proj.sh || exit 136
  elif [ "$proj" = "kubearmor" ]
  then
    PROJ=kubearmor           PROJDB=kubearmor      PROJREPO="kubearmor/KubeArmor"             ORGNAME=KubeArmor         PORT=3118 ICON=kubearmor      GRAFSUFF=kubearmor      GA="UA-145264316-79" ./devel/deploy_proj.sh || exit 137
  elif [ "$proj" = "k8up" ]
  then
    PROJ=k8up                PROJDB=k8up           PROJREPO="k8up-io/k8up"                    ORGNAME=K8up              PORT=3119 ICON=k8up           GRAFSUFF=k8up           GA="UA-145264316-80" ./devel/deploy_proj.sh || exit 138
  elif [ "$proj" = "kubers" ]
  then
    PROJ=kubers              PROJDB=kubers         PROJREPO="kube-rs/kube-rs"                 ORGNAME=kube-rs           PORT=3120 ICON=kubers         GRAFSUFF=kubers         GA="UA-145264316-81" ./devel/deploy_proj.sh || exit 139
  elif [ "$proj" = "devfile" ]
  then
    PROJ=devfile             PROJDB=devfile        PROJREPO="devfile/api"                     ORGNAME=devfile           PORT=3121 ICON=devfile        GRAFSUFF=devfile        GA="UA-145264316-82" ./devel/deploy_proj.sh || exit 140
  elif [ "$proj" = "knative" ]
  then
    PROJ=knative             PROJDB=knative        PROJREPO="knative/serving"                 ORGNAME=Knative           PORT=3122 ICON=knative        GRAFSUFF=knative        GA="UA-145264316-83" ./devel/deploy_proj.sh || exit 41
  elif [ "$proj" = "fabedge" ]
  then
    PROJ=fabedge             PROJDB=fabedge        PROJREPO="FabEdge/fabedge"                 ORGNAME=FabEdge           PORT=3123 ICON=fabedge        GRAFSUFF=fabedge        GA="UA-145264316-84" ./devel/deploy_proj.sh || exit 42
  elif [ "$proj" = "confidentialcontainers" ]
  then
    PROJ=confidentialcontainers PROJDB=confidentialcontainers PROJREPO="confidential-containers/operator" ORGNAME='Confidential Containers' PORT=3124 ICON=confidentialcontainers GRAFSUFF=confidentialcontainers GA="UA-145264316-85" ./devel/deploy_proj.sh || exit 43
  elif [ "$proj" = "openfunction" ]
  then
    PROJ=openfunction        PROJDB=openfunction   PROJREPO="OpenFunction/OpenFunction"       ORGNAME=OpenFunction      PORT=3125 ICON=openfunction   GRAFSUFF=openfunction   GA="UA-145264316-86" ./devel/deploy_proj.sh || exit 44
  elif [ "$proj" = "teller" ]
  then
    PROJ=teller              PROJDB=teller         PROJREPO="SpectralOps/teller"              ORGNAME=Teller            PORT=3126 ICON=teller         GRAFSUFF=teller         GA="UA-145264316-87" ./devel/deploy_proj.sh || exit 45
  elif [ "$proj" = "sealer" ]
  then
    PROJ=sealer              PROJDB=sealer         PROJREPO="alibaba/sealer"                  ORGNAME=sealer            PORT=3127 ICON=sealer         GRAFSUFF=sealer         GA="UA-145264316-88" ./devel/deploy_proj.sh || exit 46
  elif [ "$proj" = "clusterpedia" ]
  then
    PROJ=clusterpedia        PROJDB=clusterpedia   PROJREPO="clusterpedia-io/clusterpedia"    ORGNAME=Clusterpedia      PORT=3128 ICON=clusterpedia   GRAFSUFF=clusterpedia   GA="UA-145264316-89" ./devel/deploy_proj.sh || exit 47
  elif [ "$proj" = "opencost" ]
  then
    PROJ=opencost            PROJDB=opencost       PROJREPO="kubecost/opencost"               ORGNAME=OpenCost          PORT=3129 ICON=opencost       GRAFSUFF=opencost       GA="UA-145264316-90" ./devel/deploy_proj.sh || exit 48
  elif [ "$proj" = "aerakimesh" ]
  then
    PROJ=aerakimesh          PROJDB=aerakimesh     PROJREPO="aeraki-mesh/aeraki"              ORGNAME='Aeraki Mesh'     PORT=3130 ICON=aerakimesh     GRAFSUFF=aerakimesh     GA="UA-145264316-91" ./devel/deploy_proj.sh || exit 49
  elif [ "$proj" = "curve" ]
  then
    PROJ=curve               PROJDB=curve          PROJREPO="opencurve/curve"                 ORGNAME=Curve             PORT=3131 ICON=curve          GRAFSUFF=curve          GA="UA-145264316-92" ./devel/deploy_proj.sh || exit 50
  elif [ "$proj" = "openfeature" ]
  then
    PROJ=openfeature         PROJDB=openfeature    PROJREPO="open-feature/spec"               ORGNAME=OpenFeature       PORT=3132 ICON=openfeature    GRAFSUFF=openfeature    GA="UA-145264316-93" ./devel/deploy_proj.sh || exit 51
  elif [ "$proj" = "kubewarden" ]
  then
    PROJ=kubewarden          PROJDB=kubewarden     PROJREPO="kubewarden/kubewarden-controller" ORGNAME=kubewarden       PORT=3133 ICON=kubewarden     GRAFSUFF=kubewarden     GA="UA-145264316-94" ./devel/deploy_proj.sh || exit 52
  elif [ "$proj" = "devstream" ]
  then
    PROJ=devstream           PROJDB=devstream      PROJREPO="devstream-io/devstream"          ORGNAME=DevStream         PORT=3134 ICON=devstream      GRAFSUFF=devstream      GA="UA-145264316-95" ./devel/deploy_proj.sh || exit 53
  elif [ "$proj" = "hexapolicyorchestrator" ]
  then
    PROJ=hexapolicyorchestrator PROJDB=hexapolicyorchestrator PROJREPO="hexa-org/policy-orchestrator" ORGNAME="Hexa Policy Orchestrator" PORT=3135 ICON=hexapolicyorchestrator GRAFSUFF=hexapolicyorchestrator GA="UA-145264316-96" ./devel/deploy_proj.sh || exit 54
  elif [ "$proj" = "konveyor" ]
  then
    PROJ=konveyor            PROJDB=konveyor       PROJREPO="konveyor/mig-operator"           ORGNAME=Konveyor          PORT=3136 ICON=konveyor       GRAFSUFF=konveyor       GA="UA-145264316-97" ./devel/deploy_proj.sh || exit 55
  elif [ "$proj" = "armada" ]
  then
    PROJ=armada              PROJDB=armada         PROJREPO="G-Research/armada"               ORGNAME=Armada            PORT=3137 ICON=armada         GRAFSUFF=armada         GA="UA-145264316-98" ./devel/deploy_proj.sh || exit 56
  elif [ "$proj" = "externalsecretsoperator" ]
  then
    PROJ=externalsecretsoperator PROJDB=externalsecretsoperator PROJREPO="external-secrets/external-secrets" ORGNAME="External Secrets Operator" PORT=3138 ICON=externalsecretsoperator GRAFSUFF=externalsecretsoperator GA="UA-145264316-99" ./devel/deploy_proj.sh || exit 57
  elif [ "$proj" = "serverlessdevs" ]
  then
         PROJ=serverlessdevs PROJDB=serverlessdevs PROJREPO="Serverless-Devs/Serverless-Devs" ORGNAME='Serverless Devs' PORT=3139 ICON=serverlessdevs GRAFSUFF=serverlessdevs GA="UA-145264316-100" ./devel/deploy_proj.sh || exit 141
  elif [ "$proj" = "containerssh" ]
  then
         PROJ=containerssh   PROJDB=containerssh   PROJREPO="ContainerSSH/ContainerSSH"       ORGNAME=ContainerSSH      PORT=3140 ICON=containerssh   GRAFSUFF=containerssh   GA="UA-241436121-1" ./devel/deploy_proj.sh || exit 142
  elif [ "$proj" = "openfga" ]
  then
         PROJ=openfga        PROJDB=openfga        PROJREPO="openfga/openfga"                 ORGNAME=OpenFGA           PORT=3141 ICON=openfga        GRAFSUFF=openfga        GA="UA-241436121-2" ./devel/deploy_proj.sh || exit 143
  elif [ "$proj" = "kured" ]
  then
         PROJ=kured          PROJDB=kured          PROJREPO="kubereboot/kured"                ORGNAME=Kured             PORT=3142 ICON=kured          GRAFSUFF=kured          GA="UA-241436121-3" ./devel/deploy_proj.sh || exit 144
  elif [ "$proj" = "carvel" ]
  then
         PROJ=carvel         PROJDB=carvel         PROJREPO="vmware-tanzu/carvel-kapp"        ORGNAME=Carvel            PORT=3143 ICON=carvel         GRAFSUFF=carvel         GA="UA-241436121-4" ./devel/deploy_proj.sh || exit 145
  elif [ "$proj" = "lima" ]
  then
         PROJ=lima           PROJDB=lima           PROJREPO="lima-vm/lima"                    ORGNAME=Lima              PORT=3144 ICON=lima           GRAFSUFF=lima           GA="UA-241436121-5" ./devel/deploy_proj.sh || exit 146
  elif [ "$proj" = "istio" ]
  then
    PROJ=istio               PROJDB=istio          PROJREPO="istio/istio"                     ORGNAME=Istio             PORT=3221 ICON=istio          GRAFSUFF=istio          GA="UA-241436121-6"  ./devel/deploy_proj.sh || exit 34
  elif [ "$proj" = "merbridge" ]
  then
    PROJ=merbridge           PROJDB=merbridge      PROJREPO="merbridge/merbridge"             ORGNAME=Merbridge         PORT=3222 ICON=merbridge      GRAFSUFF=merbridge      GA="UA-241436121-7"  ./devel/deploy_proj.sh || exit 147
  elif [ "$proj" = "devspace" ]
  then
    PROJ=devspace            PROJDB=devspace       PROJREPO="devspace-cloud/devspace-cloud"   ORGNAME=DevSpace          PORT=3223 ICON=devspace       GRAFSUFF=devspace       GA="UA-241436121-8"  ./devel/deploy_proj.sh || exit 148
  elif [ "$proj" = "capsule" ]
  then
    PROJ=capsule             PROJDB=capsule        PROJREPO="cpasule-rs/capsule"              ORGNAME=capsule           PORT=3224 ICON=capsule        GRAFSUFF=capsule        GA="UA-241436121-9"  ./devel/deploy_proj.sh || exit 149
  elif [ "$proj" = "zot" ]
  then
    PROJ=zot                 PROJDB=zot            PROJREPO="project-zot/zot"                 ORGNAME=zot               PORT=3225 ICON=zot            GRAFSUFF=zot            GA="UA-241436121-10" ./devel/deploy_proj.sh || exit 150
  elif [ "$proj" = "paralus" ]
  then
    PROJ=paralus             PROJDB=paralus        PROJREPO="paralus/paralus"                 ORGNAME=paralus           PORT=3226 ICON=paralus        GRAFSUFF=paralus        GA="UA-241436121-11" ./devel/deploy_proj.sh || exit 151
  elif [ "$proj" = "carina" ]
  then
    PROJ=carina              PROJDB=carina         PROJREPO="carina-io/carina"                ORGNAME=Carina            PORT=3227 ICON=carina         GRAFSUFF=carina         GA="UA-241436121-12" ./devel/deploy_proj.sh || exit 152
  elif [ "$proj" = "ko" ]
  then
    PROJ=ko                  PROJDB=ko             PROJREPO="ko-build/ko"                     ORGNAME=ko                PORT=3228 ICON=ko             GRAFSUFF=ko             GA="UA-241436121-13" ./devel/deploy_proj.sh || exit 153
  elif [ "$proj" = "opcr" ]
  then
    PROJ=opcr                PROJDB=opcr           PROJREPO="opcr-io/policy"                  ORGNAME=OPCR              PORT=3229 ICON=opcr           GRAFSUFF=opcr           GA="UA-241436121-14" ./devel/deploy_proj.sh || exit 154
  elif [ "$proj" = "werf" ]
  then
    PROJ=werf                PROJDB=werf           PROJREPO="werf/werf"                       ORGNAME=werf              PORT=3230 ICON=werf           GRAFSUFF=werf           GA="UA-241436121-15" ./devel/deploy_proj.sh || exit 155
  elif [ "$proj" = "kubescape" ]
  then
    PROJ=kubescape           PROJDB=kubescape      PROJREPO="kubescape/kubescape"             ORGNAME=Kubescape         PORT=3231 ICON=kubescape      GRAFSUFF=kubescape      GA="UA-241436121-16" ./devel/deploy_proj.sh || exit 156
  elif [ "$proj" = "opencontainers" ]
  then
    PROJ=opencontainers      PROJDB=opencontainers PROJREPO="opencontainers/runc"             ORGNAME=OCI               PORT=3220 ICON="-"            GRAFSUFF=opencontainers GA="UA-108085315-19" ./devel/deploy_proj.sh || exit 32
  elif [ "$proj" = "cncf" ]
  then
    PROJ=cncf                PROJDB=cncf           PROJREPO="cncf/landscapeapp"               ORGNAME=CNCF              PORT=3255 ICON=cncf           GRAFSUFF=cncf           GA="UA-108085315-8"  ./devel/deploy_proj.sh || exit 33
  elif [ "$proj" = "sam" ]
  then
    PROJ=sam                 PROJDB=sam            PROJREPO="awslabs/serverless-application-model" ORGNAME="AWS SAM"    PORT=3224 ICON=cncf           GRAFSUFF=sam            GA="-"               ./devel/deploy_proj.sh || exit 54
  elif [ "$proj" = "azf" ]
  then
    PROJ=azf                 PROJDB=azf            PROJREPO="Azure/azure-webjobs-sdk"         ORGNAME=AZF               PORT=3225 ICON=cncf           GRAFSUFF=azf            GA="-"               ./devel/deploy_proj.sh || exit 55
  elif [ "$proj" = "riff" ]
  then
    PROJ=riff                PROJDB=riff           PROJREPO="projectriff/riff"                ORGNAME="Pivotal Riff"    PORT=3226 ICON=cncf           GRAFSUFF=riff           GA="-"               ./devel/deploy_proj.sh || exit 56
  elif [ "$proj" = "fn" ]
  then
    PROJ=fn                  PROJDB=fn             PROJREPO="fnproject/fn"                    ORGNAME="Oracle Fn"       PORT=3227 ICON=cncf           GRAFSUFF=fn             GA="-"               ./devel/deploy_proj.sh || exit 57
  elif [ "$proj" = "openwhisk" ]
  then
    PROJ=openwhisk           PROJDB=openwhisk      PROJREPO="apache/openwhisk"                ORGNAME="Apache OpenWhisk" PORT=3228 ICON=cncf          GRAFSUFF=openwhisk      GA="-"               ./devel/deploy_proj.sh || exit 58
  elif [ "$proj" = "openfaas" ]
  then
    PROJ=openfaas            PROJDB=openfaas       PROJREPO="openfaas/faas"                   ORGNAME="OpenFaaS"        PORT=3229 ICON=cncf           GRAFSUFF=openfaas       GA="-"               ./devel/deploy_proj.sh || exit 59
  elif [ "$proj" = "cii" ]
  then
    PROJ=cii                 PROJDB=cii            PROJREPO="not/used"                        ORGNAME="CII"             PORT=3130 ICON=cncf           GRAFSUFF=cii            GA="-"               ./devel/deploy_proj.sh || exit 62
  elif [ "$proj" = "prestodb" ]
  then
    PROJ=prestodb            PROJDB=prestodb       PROJREPO="presto/prestodb"                 ORGNAME="Presto"          PORT=3131 ICON=prestodb       GRAFSUFF=prestodb       GA="-"               ./devel/deploy_proj.sh || exit 63
  elif [ "$proj" = "godotengine" ]
  then
    PROJ=godotengine         PROJDB=godotengine    PROJREPO="godotengine/godot"               ORGNAME="Godot Engine"    PORT=3132 ICON=godotengine    GRAFSUFF=godotengine    GA="-"               ./devel/deploy_proj.sh || exit 90
  elif [ "$proj" = "all" ]
  then
    PROJ=all                 PROJDB=allprj         PROJREPO="not/used"                        ORGNAME="All CNCF"        PORT=3254 ICON=cncf           GRAFSUFF=all            GA="UA-108085315-20" ./devel/deploy_proj.sh || exit 36
  else
    echo "Unknown project: $proj"
    exit 28
  fi
done

if [ -z "$SKIPCERT" ]
then
  export CERT=1
fi

if [ -z "$SKIPWWW" ]
then
  WWW=1 ./devel/create_www.sh || exit 37
fi
if [ -z "$SKIPVARS" ]
then
  ./devel/vars_all.sh || exit 38
fi

if [ -z "$SKIPICONS" ]
then
  ./devel/icons_all.sh || exit 47
fi
if [ -z "$SKIPMAKE" ]
then
  rm -f /tmp/deploy.wip 2>/dev/null
  make install || exit 48
fi

echo "$0: All deployments finished"
