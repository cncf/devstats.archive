#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes prometheus opentracing" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" devstats
ONLY="fluentd linkerd grpc coredns containerd" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" devstats
ONLY="rkt cni envoy jaeger notary tuf rook vitess nats opa" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" devstats
ONLY="spiffe spire cloudevents telepresence helm openmetrics harbor etcd tikv cortex" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" devstats
ONLY="buildpacks falco dragonfly virtualkubelet all" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" devstats
