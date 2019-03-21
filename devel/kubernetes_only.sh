#!/bin/bash
GHA2DB_PROJECT=kubernetes PG_DB=gha ./shared/get_repos.sh || exit 1
GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 ./vars || exit 2
# PG_DB=gha PG_HOST=localhost GHA2DB_LOCAL=1 GHA2DB_PROJECTS_YAML=./kubernetes.yaml GHA2DB_GITHUB_OAUTH="-" GHA2DB_GHAPISKIP=1 GHA2DB_AECLEANSKIP=1 GHA2DB_GETREPOSSKIP=1 devstats
PROJ=kubernetes PROJDB=gha PROJREPO="kubernetes/kubernetes" ORGNAME=Kubernetes PORT=2999 ICON=kubernetes GRAFSUFF=k8s GA="UA-108085315-1" SKIPGRAFANA=1 GHA2DB_LOCAL=1 GHA2DB_GITHUB_OAUTH="-" GHA2DB_GHAPISKIP=1 GHA2DB_AECLEANSKIP=1 ./devel/deploy_proj.sh || exit 3
echo 'All OK'
