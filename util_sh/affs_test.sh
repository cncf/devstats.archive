#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="prometheus opentracing" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="fluentd linkerd grpc coredns containerd rkt cni" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="envoy jaeger notary tuf rook vitess nats opa spiffe spire" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="cloudevents telepresence helm openmetrics harbor etcd" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="tikv cortex buildpacks falco dragonfly virtualkubelet cncf" GHA2DB_PROJECTS_OVERRIDE="+cncf" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="opencontainers istio spinnaker knative" GHA2DB_PROJECTS_OVERRIDE="+opencontainers,+istio,+spinnaker,+knative" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats

ONLY="linux all" ./devel/all_affs.sh
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+spinnaker,+knative" devstats
