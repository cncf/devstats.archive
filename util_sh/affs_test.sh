#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes prometheus opentracing" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats
ONLY="fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opa spiffe spire" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats
ONLY="cloudevents telepresence helm openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet cncf" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats
ONLY="opencontainers istio spinnaker knative all" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" ./devel/all_affs.sh
GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats
