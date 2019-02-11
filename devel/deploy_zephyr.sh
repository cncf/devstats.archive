#!/bin/bash
# CUSTGRAFPATH=1 (set this to use non-standard grafana instalation from ~/grafana.v5/)
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi

if [ ! -z "$CUSTGRAFPATH" ]
then
  GRAF_USRSHARE="$HOME/grafana.v5/usr.share.grafana"
  GRAF_VARLIB="$HOME/grafana.v5/var.lib.grafana"
  GRAF_ETC="$HOME/grafana.v5/etc.grafana"
fi

if [ -z "$GRAF_USRSHARE" ]
then
  GRAF_USRSHARE="/usr/share/grafana"
fi
if [ -z "$GRAF_VARLIB" ]
then
  GRAF_VARLIB="/var/lib/grafana"
fi
if [ -z "$GRAF_ETC" ]
then
  GRAF_ETC="/etc/grafana"
fi
export GRAF_USRSHARE
export GRAF_VARLIB
export GRAF_ETC
export GHA2DB_PROJECTS_OVERRIDE="+zephyr"
export GHA2DB_PROJECTS_YAML="zephyr.yaml"

host=`hostname`
function finish {
    sync_unlock.sh
    rm -f /tmp/deploy.wip 2>/dev/null
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi

PROJ=zephyr PROJDB=zephyr PROJREPO="zephyrproject-rtos/zephyr" ORGNAME=Zephyr PORT=3257 ICON=cncf GRAFSUFF=zephyr GA="-" ./devel/deploy_proj.sh || exit 1
CERT=1 WWW=1 ./devel/create_www.sh || exit 2
echo "$0: All deployments finished"
