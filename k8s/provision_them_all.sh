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
  exit 1
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
    exit 1
  fi
  sleep 1
done
echo "Initial setup (blocking) complete, now spawn N provision pods in parallel"

# iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord envoy zephyr linux
PROJ=iovisor                PROJDB=iovisor                PROJREPO='iovisor/bcc'                     ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=mininet                PROJDB=mininet                PROJREPO='mininet/mininet'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=opennetworkinglab      PROJDB=opennetworkinglab      PROJREPO='opennetworkinglab/onos'          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=opensecuritycontroller PROJDB=opensecuritycontroller PROJREPO='opensecuritycontroller/osc-core' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=openswitch             PROJDB=openswitch             PROJREPO='open-switch/opx-nas-interface'   ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=p4lang                 PROJDB=p4lang                 PROJREPO='p4lang/p4c'                      ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=openbmp                PROJDB=openbmp                PROJREPO='OpenBMP/openbmp'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=tungstenfabric         PROJDB=tungstenfabric         PROJREPO='tungstenfabric/website'          ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=cord                   PROJDB=cord                   PROJREPO='opencord/voltha'                 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=envoy                  PROJDB=envoy                  PROJREPO='envoyproxy/envoy'                ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=zephyr                 PROJDB=zephyr                 PROJREPO='zephyrproject-rtos/zephyr'       ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
PROJ=linux                  PROJDB=linux                  PROJREPO='torvalds/linux'                  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml
sleep 2
echo "Spawned provisioning pods"
kubectl get po -l name=devstats
