#!/bin/bash
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 1
fi
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics docker devel util_sql all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron vendor util_sh/touch *.go projects.yaml companies.yaml linux.yaml zephyr.yaml github_users.json Makefile
docker build -f Dockerfile -t "${DOCKER_USER}/devstats" .
docker build -f docker/Dockerfile.minimal.debug -t "${DOCKER_USER}/devstats-minimal" .
# Dockerfile.minimal.debug creates container with a working '/bin/sh' command. Dockerfile.minimal creates DevStats binaries only, even without any shell.
#docker build -f docker/Dockerfile.minimal -t "${DOCKER_USER}/devstats-minimal" .
rm -f devstats.tar
docker tag devstats "${DOCKER_USER}/devstats"
docker tag devstats-minimal "${DOCKER_USER}/devstats-minimal"
docker push "${DOCKER_USER}/devstats"
docker push "${DOCKER_USER}/devstats-minimal"
