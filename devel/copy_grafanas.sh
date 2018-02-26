#!/bin/sh
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opnecontainers all cncf"
else
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all"
fi
killall grafana-server
for proj in $all
do
    echo $proj
    rm -rf /usr/share/grafana.$proj
    cp -R /usr/share/grafana /usr/share/grafana.$proj || exit 1
    rm -rf /var/lib/grafana.$proj
    cp -R /var/lib/grafana /var/lib/grafana.$proj || exit 2
done
echo 'OK'
./grafana/change_title_and_icons_all.sh || exit 3
./devel/get_grafana_dbs.sh || exit 4
./grafana/start_all_grafanas.sh || exit 5
sleep 5
ps -aux | grep 'grafana-server'
