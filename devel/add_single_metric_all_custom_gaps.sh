#!/bin/sh
for f in prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook cncf
do
  echo "$f..."
  GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_METRICS_YAML=devel/test_metrics.yaml GHA2DB_GAPS_YAML=metrics/$f/gaps_single.yaml GHA2DB_TAGS_YAML=devel/test_tags.yaml GHA2DB_LOCAL=1 PG_DB=$f IDB_DB=$f ./gha2db_sync || exit 1
done
echo 'OK'
