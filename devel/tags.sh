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
./kubernetes/tags.sh || exit 1
./prometheus/tags.sh || exit 2
./opentracing/tags.sh || exit 3
./fluentd/tags.sh || exit 4
./linkerd/tags.sh || exit 5
./grpc/tags.sh || exit 6
./coredns/tags.sh || exit 7
./containerd/tags.sh || exit 8
./rkt/tags.sh || exit 9
./cni/tags.sh || exit 10
./envoy/tags.sh || exit 11
./jaeger/tags.sh || exit 12
./notary/tags.sh || exit 13
./tuf/tags.sh || exit 14
./rook/tags.sh || exit 15
./vitess/tags.sh || exit 16
./nats/tags.sh || exit 17
./all/tags.sh || exit 18
./opencontainers/tags.sh || exit 19
host=`hostname`
if [ $host = "cncftest.io" ]
then
  ./cncf/tags.sh || exit 20
fi
