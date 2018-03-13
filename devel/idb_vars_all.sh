#!/bin/bash
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opencontainers all cncf"
else
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opencontainers all"
fi
for f in $all
do
    db=$f
    if [ $f = "kubernetes" ]
    then
      db="gha"
    elif [ $f = "all" ]
    then
      db="allprj"
    fi
    echo "Project: $f, IDB: $db"
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$f IDB_DB=$db ./idb_vars
done
echo 'OK'
