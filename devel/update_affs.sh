#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 ./get_repos
./kubernetes/update_affs.sh || exit 1
./prometheus/update_affs.sh || exit 2
./opentracing/update_affs.sh || exit 3
./fluentd/update_affs.sh || exit 4
./linkerd/update_affs.sh || exit 5
./grpc/update_affs.sh || exit 6
./coredns/update_affs.sh || exit 7
./containerd/update_affs.sh || exit 8
./rkt/update_affs.sh || exit 9
./cni/update_affs.sh || exit 10
./envoy/update_affs.sh || exit 11
./jaeger/update_affs.sh || exit 12
./notary/update_affs.sh || exit 13
./tuf/update_affs.sh || exit 14
./rook/update_affs.sh || exit 15
./vitess/update_affs.sh || exit 16
./nats/update_affs.sh || exit 17
./all/update_affs.sh || exit 18
./opencontainers/update_affs.sh || exit 19
host=`hostname`
if [ $host = "cncftest.io" ]
then
  ./cncf/update_affs.sh || exit 20
fi
