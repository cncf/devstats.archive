#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
ONLY="kubernetes prometheus opentracing" ./devel/all_affs.sh || exit 2
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="fluentd linkerd grpc coredns containerd rkt cni" ./devel/all_affs.sh || exit 3
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="envoy jaeger notary tuf rook vitess nats opa spiffe spire" ./devel/all_affs.sh || exit 4
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="cloudevents telepresence helm openmetrics harbor etcd" ./devel/all_affs.sh || exit 5
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="tikv cortex buildpacks falco dragonfly virtualkubelet kubeedge brigade" ./devel/all_affs.sh || exit 6
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="crio networkservicemesh openebs opentelemetry thanos flux intoto strimzi kubevirt longhorn chubaofs keda" ./devel/all_affs.sh || exit 7
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="smi argo volcano cnigenie keptn kudo cloudcustodian dex litmuschaos artifacthub kuma parsec bfe crossplane" ./devel/all_affs.sh || exit 8
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="contour operatorframework chaosmesh serverlessworkflow k3s backstage tremor metal3 porter openyurt openservicemesh keylime" ./devel/all_affs.sh || exit 9
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="schemahero cdk8s certmanager openkruise tinkerbell pravega kyverno gitopswg piraeus k8dash athenz kubeovn curiefense" ./devel/all_affs.sh || exit 10
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="distribution ingraind kuberhealthy k8gb trickster emissaryingress wasmedge chaosblade vineyard antrea fluid submariner" ./devel/all_affs.sh || exit 11
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="pixie meshery servicemeshperformance kubevela kubevip kubedl krustlet krator oras wasmcloud akri metallb karmada" ./devel/all_affs.sh || exit 12
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="inclavarecontainers superedge cilium dapr openelb openclustermanagement vscodek8stools nocalhost kubearmor" ./devel/all_affs.sh || exit 13
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="k8up kubers devfile knative fabedge confidentialcontainers openfunction teller sealer" ./devel/all_affs.sh || exit 14
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="cncf opencontainers istio sam azf riff fn openwhisk openfaas" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" ./devel/all_affs.sh || exit 15
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+sam,+azf,+riff,+fn,+openwhisk,+openfaas" devstats

ONLY="linux zephyr cii prestodb godotengine all" GHA2DB_PROJECTS_OVERRIDE="+linux,+zephyr,+cii" ./devel/all_affs.sh || exit 16
GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+linux,+zephyr,+sam,+azf,+riff,+fn,+openwhisk,+openfaas,+cii" devstats

./devel/columns_all.sh
