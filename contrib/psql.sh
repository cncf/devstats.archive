#!/bin/bash
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
start_date="2015-01-01"
#start_date="2019-02-01"
GHA2DB_PROJECT=contrib PG_DB=contrib GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
sudo -u postgres psql contrib -c "create extension if not exists pgcrypto" || exit 1
./devel/ro_user_grants.sh contrib || exit 2
GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/cli-runtime,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin,kubernetes/cluster-bootstrap,kubernetes/cloud-provider' GHA2DB_PROJECT=contrib PG_DB=contrib GHA2DB_LOCAL=1 gha2db "${start_date}" 0 today now 'OpenStack-mobile,openstack,openstack-ansible,kata-containers,openstack-charmers,openstack-dev,openstacknetsdk,openstack-hyper-v,openstack-infra,openstack-kr,openstack-packages,openstack-snaps,kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-retired,kubernetes-sigs,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-charts,prometheus,opentracing,fluent,linkerd,grpc,coredns,containerd,rkt,containernetworking,envoyproxy,jaegertracing,theupdateframework,rook,cncf,crosscloudci,vitessio,nats-io,open-policy-agent,spiffe,cloudevents,telepresenceio,helm,kubernetes-csi,goharbor,tikv,etcd-io,OpenObservability,cortexproject,buildpack,falcosecurity,dragonflyoss,virtual-kubelet,kubeedge,brigadecore,cri-o,networkservicemesh' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=contrib PG_DB=contrib GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=contrib PG_DB=contrib ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=contrib PG_DB=contrib ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=contrib PG_DB=contrib ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=contrib PG_DB=contrib GHA2DB_LOCAL=1 vars || exit 8
