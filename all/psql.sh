#!/bin/bash
# MERGE_MODE=1 (use merge DBs mode instead of generating data via 'gha2db')
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql allprj -c "create extension if not exists pgcrypto" || exit 2
if [ ! -z "$MERGE_MODE" ]
  exclude="kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin"
  args="kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-csi,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired,GoogleCloudPlatform/kubernetes"
  args="${args},prometheus,opentracing,fluent,linkerd,BuoyantIO/linkerd,grpc,miekg/coredns,coredns,containerd,docker/containerd,rkt,coreos/rkt,coreos/rocket,rktproject/rkt,containernetworking,appc/cni,envoyproxy,lyft/envoy,jaegertracing,uber/jaeger,theupdateframework,docker/notary,rook,vitessio,youtube/vitess,nats-io,apcera/nats,apcera/gnatsd"
  args="${args},open-policy-agent,spiffe,cloudevents,openeventing,telepresenceio,datawire/telepresence,helm,kubernetes-helm,kubernetes-charts,kubernetes/helm,kubernetes/charts,kubernetes/deployment-manager,kubernetes/application-dm-templates,OpenObservability,RichiH/OpenMetrics,goharbor,vmware/harbor,coreos/etcd,etcd,etcd-io,pingcap/tikv,tikv"
  args="${args},cortexproject,weaveworks/cortex,weaveworks/prism,weaveworks/frankenstein,buildpack,falcosecurity,draios/falco,dragonflyoss,alibaba/Dragonfly,virtual-kubelet,Virtual-Kubelet,kubeedge,brigadecore,Azure/brigade,kubernetes-incubator/ocid,kubernetes-incubator/cri-o,kubernetes-sigs/cri-o,cri-o,networkservicemesh,NetworkServiceMesh,ligato/networkservicemesh"
  args="${args},openebs,open-telemetry,thanos-io,improbable-eng/promlts,improbable-eng/thanos,fluxcd,weaveworks/flux,in-toto"
  GHA2DB_EXCLUDE_REPOS=$exclude GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now "$args" 2>>errors.txt | tee -a run.log || exit 3
  args="GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi,prometheus/prometheus,fluent,rocket,theupdateframework,tuf,vitessio,youtube/vitess,nats-io,apcera/nats,apcera/gnatsd,etcd"
  GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-01-02 0 2014-12-31 23 "$args" 2>>errors.txt | tee -a run.log || exit 4
then
  GHA2DB_INPUT_DBS="gha,prometheus,opentracing,fluentd,linkerd,grpc,coredns,containerd,rkt,cni,envoy,jaeger,notary,tuf,rook,vitess,nats,cncf,opa,spiffe,spire,cloudevents,telepresence,helm,openmetrics,harbor,etcd,tikv,cortex,buildpacks,falco,dragonfly,virtualkubelet,kubeedge,brigade,crio,networkservicemesh,openebs,opentelemetry,thanos,flux,intoto" GHA2DB_OUTPUT_DB="allprj" merge_dbs || exit 2
else
fi
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=all PG_DB=allprj ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=all PG_DB=allprj ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_VARS="projects_health_partial_html" vars || exit 8
./devel/ro_user_grants.sh allprj || exit 10
./devel/psql_user_grants.sh devstats_team allprj || exit 11
