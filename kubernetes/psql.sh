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
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql gha -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/helm,kubernetes/deployment-manager,kubernetes/charts,kubernetes/application-dm-templates,kubernetes/cli-runtime,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin,kubernetes-sigs/cri-o,kubernetes-incubator/ocid,kubernetes-incubator/cri-o' GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 ./gha2db 2015-08-06 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-csi,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2015-08-14 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-06-02 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=kubernetes PG_DB=gha ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=kubernetes PG_DB=gha ./kubernetes/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=kubernetes PG_DB=gha ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=kubernetes PG_DB=gha ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 ./vars || exit 10
./devel/ro_user_grants.sh gha || exit 11
./devel/psql_user_grants.sh devstats_team gha || exit 12
