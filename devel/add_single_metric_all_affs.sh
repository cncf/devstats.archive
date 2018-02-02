#!/bin/sh
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess all cncf"
else
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess"
fi
for proj in $all
do
  echo $proj
  db=$proj
  if [ $db = "kubernetes" ]
  then
    db="gha"
  fi
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_METRICS_YAML=devel/test_metrics.yaml GHA2DB_GAPS_YAML=metrics/$proj/gaps_affs.yaml GHA2DB_TAGS_YAML=devel/test_tags.yaml GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db IDB_DB=$db ./gha2db_sync || exit 1
done
echo 'OK'
