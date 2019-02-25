#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
ONLY=iovisor                CRON='6 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=mininet                CRON='10 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=opennetworkinglab      CRON='14 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=opensecuritycontroller CRON='18 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=openswitch             CRON='22 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=p4lang                 CRON='26 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=openbmp                CRON='30 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=tungstenfabric         CRON='34 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=cord                   CRON='38 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=envoy                  CRON='42 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=zephyr                 CRON='46 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
ONLY=linux                  CRON='50 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml
