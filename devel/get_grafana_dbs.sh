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
    echo "wget grafana.$proj.db"
    rm -f grafana.$proj.db 2>/dev/null
    wget https://cncftest.io/grafana.$proj.db || exit 1
    ls -l grafana.$proj.db
    cp grafana.$proj.db /var/lib/grafana.$proj/grafana.db || exit 2
done
echo 'OK'

