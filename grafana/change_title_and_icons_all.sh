#!/bin/bash
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all cncf"
else
  all="kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all"
fi
for proj in $all
do
    echo $proj
    suff=$proj
    if [ $suff = "kubernetes" ]
    then
      suff="k8s"
    fi
    GRAFANA_DATA="/usr/share/grafana.${suff}/" "./grafana/${proj}/change_title_and_icons.sh" || exit 1
done
echo 'All OK'
