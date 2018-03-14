#!/bin/bash
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="gha prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opencontainers allprj cncf"
else
  all="gha prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opencontainers allprj"
fi
for proj in $all
do
  sudo -u postgres psql "$proj" < ./util_sql/vars_table.sql || exit 1
done
echo 'OK'
