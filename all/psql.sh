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
./devel/db.sh psql allprj -c "create extension if not exists pgcrypto" || exit 1
#TODO: add non-merge approach that will gather all data from all projects.
if [ ! -z "$MERGE_MODE" ]
  GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/helm,kubernetes/deployment-manager,kubernetes/charts,kubernetes/application-dm-templates,kubernetes/cli-runtime,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin,kubernetes-sigs/cri-o,kubernetes-incubator/ocid,kubernetes-incubator/cri-o'   GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 gha2db 2015-08-06 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-csi,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXACT=1 gha2db 2015-01-01 0 2015-08-14 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-06-02 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 4
  GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'prometheus' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-01-06 0 2014-12-31 23 'prometheus/prometheus' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=opentracing PG_DB=opentracing GHA2DB_LOCAL=1 gha2db 2015-11-26 0 today now 'opentracing' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now fluent 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 gha2db 2014-01-02 0 2014-12-31 23 fluent 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 gha2db 2017-01-23 0 today now 'linkerd' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 GHA2DB_EXACT=1 gha2db 2016-01-13 0 2017-01-24 0 'BuoyantIO/linkerd' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=grpc PG_DB=grpc GHA2DB_LOCAL=1 gha2db 2015-02-23 0 today now 'grpc' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=coredns PG_DB=coredns GHA2DB_LOCAL=1 gha2db 2016-03-18 0 today now 'miekg/coredns,coredns' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=containerd PG_DB=containerd GHA2DB_LOCAL=1 gha2db 2015-12-17 0 today now 'containerd,docker/containerd' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 gha2db 2017-04-04 0 today now 'rkt' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 gha2db 2015-01-01 0 2017-04-07 0 'coreos/rkt,coreos/rocket,rktproject/rkt' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 gha2db 2014-11-26 0 2014-12-31 23 'rocket' 2>>errors.txt | tee -a run.log || exit 4
  GHA2DB_PROJECT=cni PG_DB=cni GHA2DB_LOCAL=1 gha2db 2016-05-04 0 today now 'containernetworking' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=cni PG_DB=cni GHA2DB_LOCAL=1 GHA2DB_EXACT=1 gha2db 2015-04-04 0 2016-05-05 0 'appc/cni' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=envoy PG_DB=envoy GHA2DB_LOCAL=1 gha2db 2016-09-13 0 today now 'envoyproxy,lyft/envoy' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=jaeger PG_DB=jaeger GHA2DB_LOCAL=1 gha2db 2016-11-01 0 today now 'jaegertracing,uber/jaeger' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=notary PG_DB=notary GHA2DB_LOCAL=1 gha2db 2015-06-22 0 today now 'theupdateframework,docker' 'notary' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_EXCLUDE_REPOS='theupdateframework/notary'   GHA2DB_PROJECT=tuf PG_DB=tuf GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'theupdateframework' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=tuf PG_DB=tuf GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 gha2db 2014-01-02 0 2014-12-31 23 'theupdateframework,tuf' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=rook PG_DB=rook GHA2DB_LOCAL=1 gha2db 2016-11-07 0 today now 'rook' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=vitess PG_DB=vitess GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'vitessio,youtube/vitess' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=vitess PG_DB=vitess GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 gha2db 2014-01-02 0 2014-12-31 23 'vitessio,youtube/vitess' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 gha2db 2014-01-02 0 2014-03-02 16 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 gha2db 2014-03-02 18 2014-12-31 23 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=opa PG_DB=opa GHA2DB_LOCAL=1 gha2db 2015-12-27 0 today now 'open-policy-agent' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_EXCLUDE_REPOS='spiffe/spire'   GHA2DB_PROJECT=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 gha2db 2017-08-23 0 today now 'spiffe' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=spire PG_DB=spire GHA2DB_LOCAL=1 gha2db 2017-09-28 0 today now 'spiffe' 'spire' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=cloudevents PG_DB=cloudevents GHA2DB_LOCAL=1 gha2db 2017-12-09 0 today now 'cloudevents,openeventing' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=telepresence PG_DB=telepresence GHA2DB_LOCAL=1 gha2db 2017-03-02 0 today now 'telepresenceio,datawire/telepresence' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=helm PG_DB=helm GHA2DB_LOCAL=1 gha2db 2015-10-06 0 today now 'helm,kubernetes-helm,kubernetes-charts,kubernetes/helm,kubernetes/charts,kubernetes/deployment-manager,kubernetes/application-dm-templates' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=openmetrics PG_DB=openmetrics GHA2DB_LOCAL=1 gha2db 2017-06-22 0 today now 'OpenObservability,RichiH/OpenMetrics' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=harbor PG_DB=harbor GHA2DB_LOCAL=1 gha2db 2016-03-02 0 today now "goharbor,vmware/harbor" 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=etcd PG_DB=etcd GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now "coreos/etcd,etcd,etcd-io" 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=etcd PG_DB=etcd GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-01-02 0 2014-12-31 23 'etcd' 2>>errors.txt | tee -a run.log || exit 3
  GHA2DB_PROJECT=tikv PG_DB=tikv GHA2DB_LOCAL=1 gha2db 2016-04-01 0 today now "pingcap/tikv,tikv" 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=cortex PG_DB=cortex GHA2DB_LOCAL=1 gha2db 2016-09-09 0 today now 'cortexproject,weaveworks/cortex,weaveworks/prism,weaveworks/frankenstein' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=buildpacks PG_DB=buildpacks GHA2DB_LOCAL=1 gha2db 2018-06-01 0 today now buildpack 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=falco PG_DB=falco GHA2DB_LOCAL=1 gha2db 2016-05-17 0 today now 'falcosecurity,draios/falco' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=dragonfly PG_DB=dragonfly GHA2DB_LOCAL=1 gha2db 2017-11-19 0 today now 'dragonflyoss,alibaba/Dragonfly' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=virtualkubelet PG_DB=virtualkubelet GHA2DB_LOCAL=1 gha2db 2017-12-04 0 today now 'virtual-kubelet,Virtual-Kubelet' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=kubeedge PG_DB=kubeedge GHA2DB_LOCAL=1 gha2db 2018-11-12 0 today now 'kubeedge' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=brigade PG_DB=brigade GHA2DB_LOCAL=1 gha2db 2017-10-24 0 today now 'brigadecore,Azure/brigade' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=crio PG_DB=crio GHA2DB_LOCAL=1 gha2db  2016-09-09 0 today now 'kubernetes-incubator/ocid,kubernetes-incubator/cri-o,kubernetes-sigs/cri-o,cri-o' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=networkservicemesh PG_DB=networkservicemesh GHA2DB_LOCAL=1 gha2db  2018-04-10 0 today now 'networkservicemesh,NetworkServiceMesh,ligato/networkservicemesh' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=openebs PG_DB=openebs GHA2DB_LOCAL=1 gha2db  2016-08-01 0 today now 'openebs' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=opentelemetry PG_DB=opentelemetry GHA2DB_LOCAL=1 gha2db 2019-04-29 0 today now 'open-telemetry' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=thanos PG_DB=thanos GHA2DB_LOCAL=1 gha2db 2017-11-01 0 today now 'thanos-io,improbable-eng/promlts,improbable-eng/thanos' 2>>errors.txt | tee -a run.log || exit 2
  GHA2DB_PROJECT=flux PG_DB=flux GHA2DB_LOCAL=1 gha2db 2016-11-02 0 today now 'fluxcd,weaveworks/flux' 2>>errors.txt | tee -a run.log || exit 2
then
  GHA2DB_INPUT_DBS="gha,prometheus,opentracing,fluentd,linkerd,grpc,coredns,containerd,rkt,cni,envoy,jaeger,notary,tuf,rook,vitess,nats,cncf,opa,spiffe,spire,cloudevents,telepresence,helm,openmetrics,harbor,etcd,tikv,cortex,buildpacks,falco,dragonfly,virtualkubelet,kubeedge,brigade,crio,networkservicemesh,openebs,opentelemetry,thanos,flux" GHA2DB_OUTPUT_DB="allprj" merge_dbs || exit 2
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
