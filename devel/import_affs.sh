#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 2
fi
./kubernetes/import_affs.sh || exit 3
./prometheus/import_affs.sh || exit 4
./opentracing/import_affs.sh || exit 5
./fluentd/import_affs.sh || exit 6
./linkerd/import_affs.sh || exit 7
./grpc/import_affs.sh || exit 8
./coredns/import_affs.sh || exit 9
./containerd/import_affs.sh || exit 10
./rkt/import_affs.sh || exit 11
./cni/import_affs.sh || exit 12
./envoy/import_affs.sh || exit 13
./jaeger/import_affs.sh || exit 14
./notary/import_affs.sh || exit 15
./tuf/import_affs.sh || exit 16
./rook/import_affs.sh || exit 17
./vitess/import_affs.sh || exit 18
./all/import_affs.sh || exit 19
./opencontainers/import_affs.sh || exit 20
host=`hostname`
if [ $host = "cncftest.io" ]
then
  ./cncf/import_affs.sh || exit 21
fi
echo 'OK'
