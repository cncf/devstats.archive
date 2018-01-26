#!/bin/sh
# for proj in kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf cncf
for proj in kubernetes prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf
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
