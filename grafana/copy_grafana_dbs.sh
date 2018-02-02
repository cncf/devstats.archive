#!/bin/sh
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess all cncf"
else
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess"
fi
for proj in $all
do
    echo $proj
    cp "/var/lib/grafana.${proj}/grafana.db" "/var/www/html/grafana.${proj}.db" || exit 1
done
echo 'OK'
