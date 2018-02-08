#!/bin/sh
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha ./devel/add_single_metric.sh || exit 1
GHA2DB_PROJECT=prometheus PG_DB=prometheus IDB_DB=prometheus ./devel/add_single_metric.sh || exit 2
GHA2DB_PROJECT=opentracing PG_DB=opentracing IDB_DB=opentracing ./devel/add_single_metric.sh || exit 3
GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./devel/add_single_metric.sh || exit 4
GHA2DB_PROJECT=linkerd PG_DB=linkerd IDB_DB=linkerd ./devel/add_single_metric.sh || exit 5
GHA2DB_PROJECT=grpc PG_DB=grpc IDB_DB=grpc ./devel/add_single_metric.sh || exit 6
GHA2DB_PROJECT=coredns PG_DB=coredns IDB_DB=coredns ./devel/add_single_metric.sh || exit 7
GHA2DB_PROJECT=containerd PG_DB=containerd IDB_DB=containerd ./devel/add_single_metric.sh || exit 8
GHA2DB_PROJECT=rkt PG_DB=rkt IDB_DB=rkt ./devel/add_single_metric.sh || exit 9
GHA2DB_PROJECT=cni PG_DB=cni IDB_DB=cni ./devel/add_single_metric.sh || exit 10
GHA2DB_PROJECT=envoy PG_DB=envoy IDB_DB=envoy ./devel/add_single_metric.sh || exit 11
GHA2DB_PROJECT=jaeger PG_DB=jaeger IDB_DB=jaeger ./devel/add_single_metric.sh || exit 12
GHA2DB_PROJECT=notary PG_DB=notary IDB_DB=notary ./devel/add_single_metric.sh || exit 13
GHA2DB_PROJECT=tuf PG_DB=tuf IDB_DB=tuf ./devel/add_single_metric.sh || exit 14
GHA2DB_PROJECT=rook PG_DB=rook IDB_DB=rook ./devel/add_single_metric.sh || exit 15
GHA2DB_PROJECT=vitess PG_DB=vitess IDB_DB=vitess ./devel/add_single_metric.sh || exit 16
GHA2DB_PROJECT=opencontainers PG_DB=opencontainers IDB_DB=opencontainers ./devel/add_single_metric.sh || exit 17
host=`hostname`
if [ $host = "cncftest.io" ]
then
  GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./devel/add_single_metric.sh || exit 18
  GHA2DB_PROJECT=cncf PG_DB=cncf IDB_DB=cncf ./devel/add_single_metric.sh || exit 19
fi
echo 'OK'
