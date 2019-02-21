#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics k8s docker devel util_sql envoy all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron vendor util_sh/make_binary_links.sh *.go projects.yaml companies.yaml linux.yaml zephyr.yaml github_users.json Makefile
if [ -z "$SKIP_FULL" ]
then
  docker build -f Dockerfile -t "${DOCKER_USER}/devstats" .
fi
if [ -z "$SKIP_MIN" ]
then
  docker build -f docker/Dockerfile.minimal -t "${DOCKER_USER}/devstats-minimal" .
fi
rm -f devstats.tar
if [ -z "$SKIP_FULL" ]
then
  docker push "${DOCKER_USER}/devstats"
fi
if [ -z "$SKIP_MIN" ]
then
  docker push "${DOCKER_USER}/devstats-minimal"
fi
