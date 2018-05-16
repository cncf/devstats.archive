#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi
if [ -z "$2" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi

# To also sync 'gha2db' manually (if hours missing):
# PG_PASS=... GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller' ./gha2db 2018-02-02 6 2018-02-02 9 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm,prometheus,opentracing,fluent,linkerd,grpc,coredns,containerd,rkt,containernetworking,envoyproxy,jaegertracing,theupdateframework,rook,cncf,crosscloudci,vitessio,youtube,nats-io,apcera,open-policy-agent,spiffe'
# PG_PASS=... GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller' ./gha2db 2018-03-27 15 2018-03-27 18 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm'
# PG_PASS=... GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 ./gha2db 2018-03-27 15 2018-03-27 18 'fluent'

# PG_PASS=... PG_DB=gha GHA2DB_DEBUG=1 ./devel/calculate_hours.sh '2017-12-20 11' '2017-12-20 13'
./calc_metric events_h metrics/shared/events.sql "$1" "$2" h
periods="h d w m q y h24"
for period in $periods
do
  echo $period
  ./calc_metric multi_row_single_column metrics/shared/activity_repo_groups.sql "$1" "$2" "$period" multivalue
done
