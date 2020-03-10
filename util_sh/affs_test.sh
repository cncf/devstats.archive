#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes prometheus opentracing" ./devel/all_affs.sh || exit 2
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="fluentd linkerd grpc coredns containerd rkt cni" ./devel/all_affs.sh || exit 3
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="envoy jaeger notary tuf rook vitess nats opa spiffe spire" ./devel/all_affs.sh || exit 4
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="cloudevents telepresence helm openmetrics harbor etcd" ./devel/all_affs.sh || exit 5
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade" ./devel/all_affs.sh || exit 6
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="crio networkservicemesh openebs opentelemetry thanos flux intoto strimzi kubevirt longhorn chubaofs keda" ./devel/all_affs.sh || exit 7
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="cncf opencontainers istio knative sam azf riff fn openwhisk openfaas" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" ./devel/all_affs.sh || exit 8
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="linux zephyr cii all" GHA2DB_PROJECTS_OVERRIDE="+linux,+zephyr,+cii" ./devel/all_affs.sh || exit 8
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+linux,+zephyr,+sam,+azf,+riff,+fn,+openwhisk,+openfaas,+cii" devstats

./devel/columns_all.sh
