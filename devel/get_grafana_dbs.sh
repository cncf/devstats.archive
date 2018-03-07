#!/bin/sh
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all cncf"
else
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all"
fi
killall grafana-server
for proj in $all
do
    echo "wget grafana.$proj.db"
    rm -f grafana.$proj.db 2>/dev/null
    wget https://cncftest.io/grafana.$proj.db || exit 1
    ls -l grafana.$proj.db
    mv grafana.$proj.db /var/lib/grafana.$proj/grafana.db || exit 2
done
./grafana/start_all_grafanas.sh || exit 3
sleep 5
ps -aux | grep 'grafana-server'
echo 'OK'

