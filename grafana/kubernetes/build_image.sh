#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
rm -f devstats-grafana.tar 2>/dev/null
tar cf devstats-grafana.tar grafana/shared grafana/img/k8s.svg
docker build -f grafana/kubernetes/Dockerfile -t "${DOCKER_USER}/devstats-grafana-kubernetes" .
rm -f devstats-grafana.tar
#docker push "${DOCKER_USER}/devstats-grafana-kubernetes"
