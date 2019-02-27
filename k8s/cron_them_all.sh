#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
ONLY=iovisor                CRON='6 * * * *'  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 2
ONLY=mininet                CRON='7 * * * *'  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 3
ONLY=opennetworkinglab      CRON='8 * * * *'  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 4
ONLY=opensecuritycontroller CRON='9 * * * *'  ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 5
ONLY=openswitch             CRON='10 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 6
ONLY=p4lang                 CRON='11 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 7
ONLY=openbmp                CRON='12 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 8
ONLY=tungstenfabric         CRON='13 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 9
ONLY=cord                   CRON='14 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 10
ONLY=envoy                  CRON='15 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 11
ONLY=zephyr                 CRON='16 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 12
ONLY=linux                  CRON='17 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 13
ONLY=kubernetes             CRON='18 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 14
ONLY=prometheus             CRON='19 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 15
ONLY=opentracing            CRON='20 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 16
ONLY=fluentd                CRON='21 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 17
ONLY=linkerd                CRON='22 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 18
ONLY=grpc                   CRON='23 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 19
ONLY=coredns                CRON='24 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 20
ONLY=containerd             CRON='25 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 21
ONLY=rkt                    CRON='26 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 22
ONLY=cni                    CRON='27 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 23
ONLY=jaeger                 CRON='28 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 24
ONLY=notary                 CRON='29 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 25
ONLY=tuf                    CRON='30 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 26
ONLY=rook                   CRON='31 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 27
ONLY=vitess                 CRON='32 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 28
ONLY=nats                   CRON='33 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 29
ONLY=opa                    CRON='34 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 30
ONLY=spiffe                 CRON='35 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 31
ONLY=spire                  CRON='36 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 32
ONLY=cloudevents            CRON='37 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 33
ONLY=telepresence           CRON='38 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 34
ONLY=helm                   CRON='39 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 35
ONLY=openmetrics            CRON='40 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 36
ONLY=harbor                 CRON='41 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 37
ONLY=etcd                   CRON='42 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 38
ONLY=tikv                   CRON='43 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 39
ONLY=cortex                 CRON='44 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 40
ONLY=buildpacks             CRON='45 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 41
ONLY=falco                  CRON='46 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 42
ONLY=dragonfly              CRON='47 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 43
ONLY=virtualkubelet         CRON='48 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 44
ONLY=cncf                   CRON='49 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 45
ONLY=opencontainers         CRON='50 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 46
ONLY=istio                  CRON='51 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 47
ONLY=spinnaker              CRON='52 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 48
ONLY=knative                CRON='53 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml || exit 49
