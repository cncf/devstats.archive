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
GHA2DB_PROJECT=all IDB_DB=allprj PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y ./structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_INPUT_DBS="gha,prometheus,opentracing,fluentd,linkerd,grpc,coredns,containerd,rkt,cni,envoy,jaeger,notary,tuf,rook,vitess,nats,cncf,opa,spiffe,spire" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 2
GHA2DB_PROJECT=all IDB_DB=allprj PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 3
./all/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
./all/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=all IDB_DB=allprj PG_DB=allprj ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=all PG_DB=allprj ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 ./pdb_vars || exit 8
./devel/ro_user_grants.sh allprj || exit 10
echo "All done. You should run ./all/reinit.sh script now."
