#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all cncf"
else
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers"
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
    echo "$f -> $db"
    ./$f/top_n_repos_groups.sh 70 >> ./metrics/$f/gaps.yaml || exit 1
done
echo 'OK'
