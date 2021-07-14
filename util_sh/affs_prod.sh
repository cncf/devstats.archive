#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

ONLY="kubernetes prometheus opentracing" ./devel/all_affs.sh || exit 2
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="fluentd linkerd grpc coredns containerd cni envoy jaeger notary" ./devel/all_affs.sh || exit 3
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="tuf rook vitess nats opa spiffe spire cloudevents telepresence helm" ./devel/all_affs.sh || exit 4
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="openmetrics harbor etcd tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade keylime" ./devel/all_affs.sh || exit 5
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="schemahero cdk8s certmanager openkruise tinkerbell pravega kyverno gitopswg piraeus k8dash athenz kubeovn curiefense distribution" ./devel/all_affs.sh || exit 6
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="distribution ingraind kuberhealthy k8gb trickster emissaryingress wasmedge chaosblade vineyard antrea fluid submariner" ./devel/all_affs.sh || exit 7
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="pixie meshery servicemeshperformance kubevela kubevip kubedl krustlet krator oras wasmcloud " ./devel/all_affs.sh || exit 8
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="crio networkservicemesh openebs opentelemetry thanos flux intoto strimzi kubevirt longhorn chubaofs keda" ./devel/all_affs.sh || exit 9
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="smi argo volcano cnigenie keptn kudo cloudcustodian dex litmuschaos artifacthub kuma parsec bfe crossplane" ./devel/all_affs.sh || exit 10
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="contour operatorframework chaosmesh serverlessworkflow k3s backstage tremor metal3 porter openyurt openservicemesh" ./devel/all_affs.sh || exit 11
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

ONLY="all" ./devel/all_affs.sh || exit 11
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

./devel/columns_all.sh
