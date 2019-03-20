#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
ret=`PROJ=iovisor PROJDB=iovisor PROJREPO='iovisor/bcc' INIT=1 ONLYINIT=1 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml`
st=$?
if [ ! "$st" = "0" ]
then
  echo "Init status non-zero: $st"
  exit 2
fi
arr=($ret)
ret=${arr[0]}
IFS='/'
arr=($ret)
unset IFS
pod=${arr[1]}
echo "Waiting for pod: $pod"
while true
do
  st=`kubectl get po $pod -o=jsonpath='{.status.phase}'`
  # echo "status: $st"
  if [ "$st" = "Succeeded" ]
  then
    break
  fi
  if ( [ "$st" = "Failed" ] || [ "$st" = "CrashLoopBackOff" ] )
  then
    echo "Exiting due to pod status: $st"
    exit 3
  fi
  sleep 1
done
echo "Initial setup (blocking) complete, now spawn N provision pods in parallel"

# iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord envoy zephyr linux
PROJ=iovisor                PROJDB=iovisor                PROJREPO='iovisor/bcc'                     ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 4
PROJ=mininet                PROJDB=mininet                PROJREPO='mininet/mininet'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 5
PROJ=opennetworkinglab      PROJDB=opennetworkinglab      PROJREPO='opennetworkinglab/onos'          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 6
PROJ=opensecuritycontroller PROJDB=opensecuritycontroller PROJREPO='opensecuritycontroller/osc-core' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 7
PROJ=openswitch             PROJDB=openswitch             PROJREPO='open-switch/opx-nas-interface'   ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 8
PROJ=p4lang                 PROJDB=p4lang                 PROJREPO='p4lang/p4c'                      ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 9
PROJ=openbmp                PROJDB=openbmp                PROJREPO='OpenBMP/openbmp'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 10
PROJ=tungstenfabric         PROJDB=tungstenfabric         PROJREPO='tungstenfabric/website'          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 11
PROJ=cord                   PROJDB=cord                   PROJREPO='opencord/voltha'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 12
PROJ=envoy                  PROJDB=envoy                  PROJREPO='envoyproxy/envoy'                ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 13
PROJ=zephyr                 PROJDB=zephyr                 PROJREPO='zephyrproject-rtos/zephyr'       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 14
PROJ=linux                  PROJDB=linux                  PROJREPO='torvalds/linux'                  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 15
PROJ=kubernetes             PROJDB=gha                    PROJREPO="kubernetes/kubernetes"           ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 16
PROJ=prometheus             PROJDB=prometheus             PROJREPO="prometheus/prometheus"           ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 17
PROJ=opentracing            PROJDB=opentracing            PROJREPO="opentracing/opentracing-go"      ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 18
PROJ=fluentd                PROJDB=fluentd                PROJREPO="fluent/fluentd"                  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 19
PROJ=linkerd                PROJDB=linkerd                PROJREPO="linkerd/linkerd"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 20
PROJ=grpc                   PROJDB=grpc                   PROJREPO="grpc/grpc"                       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 21
PROJ=coredns                PROJDB=coredns                PROJREPO="coredns/coredns"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 22
PROJ=containerd             PROJDB=containerd             PROJREPO="containerd/containerd"           ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 23
PROJ=rkt                    PROJDB=rkt                    PROJREPO="rkt/rkt"                         ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 24
PROJ=cni                    PROJDB=cni                    PROJREPO="containernetworking/cni"         ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 25
PROJ=jaeger                 PROJDB=jaeger                 PROJREPO="jaegertracing/jaeger"            ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 26
PROJ=notary                 PROJDB=notary                 PROJREPO="theupdateframework/notary"       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 27
PROJ=tuf                    PROJDB=tuf                    PROJREPO="theupdateframework/tuf"          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 28
PROJ=rook                   PROJDB=rook                   PROJREPO="rook/rook"                       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 29
PROJ=vitess                 PROJDB=vitess                 PROJREPO="vitessio/vitess"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 30
PROJ=nats                   PROJDB=nats                   PROJREPO="nats-io/gnatsd"                  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 31
PROJ=opa                    PROJDB=opa                    PROJREPO="open-policy-agent/opa"           ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 32
PROJ=spiffe                 PROJDB=spiffe                 PROJREPO="spiffe/spiffe"                   ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 33
PROJ=spire                  PROJDB=spire                  PROJREPO="spiffe/spire"                    ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 34
PROJ=cloudevents            PROJDB=cloudevents            PROJREPO="cloudevents/spec"                ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 35
PROJ=telepresence           PROJDB=telepresence           PROJREPO="telepresenceio/telepresence"     ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 36
PROJ=helm                   PROJDB=helm                   PROJREPO="kubernetes/helm"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 37
PROJ=openmetrics            PROJDB=openmetrics            PROJREPO="OpenObservability/OpenMetrics"   ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 38
PROJ=harbor                 PROJDB=harbor                 PROJREPO="goharbor/harbor"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 39
PROJ=etcd                   PROJDB=etcd                   PROJREPO="etcd-io/etcd"                    ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 40
PROJ=tikv                   PROJDB=tikv                   PROJREPO="tikv/tikv"                       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 41
PROJ=cortex                 PROJDB=cortex                 PROJREPO="cortexproject/cortex"            ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 42
PROJ=buildpacks             PROJDB=buildpacks             PROJREPO="buildpack/lifecycle"             ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 43
PROJ=falco                  PROJDB=falco                  PROJREPO="falcosecurity/falco"             ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 44
PROJ=dragonfly              PROJDB=dragonfly              PROJREPO="dragonflyoss/Dragonfly"          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 45
PROJ=virtualkubelet         PROJDB=virtualkubelet         PROJREPO="virtual-kubelet/virtual-kubelet" ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 46
PROJ=opencontainers         PROJDB=opencontainers         PROJREPO="opencontainers/runc"             ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 47
PROJ=cncf                   PROJDB=cncf                   PROJREPO="cncf/landscape"                  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 48
PROJ=istio                  PROJDB=istio                  PROJREPO="istio/istio"                     ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 49
PROJ=spinnaker              PROJDB=spinnaker              PROJREPO="spinnaker/spinnaker"             ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 50
PROJ=knative                PROJDB=knative                PROJREPO="knative/serving"                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 51
PROJ=kubeedge               PROJDB=kubeedge               PROJREPO="kubeedge/kubeedge"               ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 52
PROJ=brigade                PROJDB=brigade                PROJREPO="Azure/brigade"                   ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 53
PROJ=crio                   PROJDB=crio                   PROJREPO="kubernetes-sigs/cri-o"           ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml || exit 54
sleep 2
echo "Spawned provisioning pods"
kubectl get po -l name=devstats
