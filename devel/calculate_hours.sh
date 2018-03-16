#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_DB}" ]
then
  echo "You need to set IDB_DB environment variable to run this script"
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
# PG_DB="allprj" PG_PASS=... ./gha2db 2018-02-02 6 2018-02-02 9 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm,prometheus,opentracing,fluent,linkerd,grpc,coredns,containerd,rkt,containernetworking,envoyproxy,jaegertracing,theupdateframework,rook,cncf,crosscloudci,vitessio,youtube,nats-io,apcera,open-policy-agent'

# PG_DB=gha IDB_DB=gha PG_PASS=... IDB_PASS=... IDB_HOST=172.17.0.1 GHA2DB_DEBUG=1 ./devel/calculate_hours.sh '2017-12-20 11' '2017-12-20 13'
./db2influx events_h metrics/kubernetes/events.sql "$1" "$2" h
periods="h d w m q y h24"
for period in $periods
do
  echo $period
  ./db2influx multi_row_single_column metrics/kubernetes/activity_repo_groups.sql "$1" "$2" "$period" multivalue
done
