#!/bin/bash
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all cncf"
else
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all"
fi
for f in $all
do
  ./grafana/$f/grafana_start.sh &
done
