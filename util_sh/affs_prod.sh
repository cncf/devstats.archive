#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="prometheus opentracing" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="fluentd linkerd grpc coredns containerd" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="rkt cni envoy jaeger notary" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="tuf rook vitess nats opa" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="spiffe spire cloudevents telepresence" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="helm openmetrics harbor etcd tikv cortex" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="buildpacks falco dragonfly virtualkubelet" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="all" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats
