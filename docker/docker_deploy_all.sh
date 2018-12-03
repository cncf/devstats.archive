#!/bin/bash
# ARTWORK
# GET=1 (attempt to fetch Postgres database from the test server)
# INIT=1 (needs PG_PASS_RO, PG_PASS_TEAM, initialize from no postgres database state, creates postgres logs database and users)
# SKIPVARS=1 (if set it will skip final Postgres vars regeneration)
# AURORA=1 - use Aurora DB
set -o pipefail
exec > >(tee run.log)
exec 2> >(tee errors.txt)
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if ( [ ! -z "$INIT" ] && ( [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] ) )
then
  echo "$0: You need to set PG_PASS_RO, PG_PASS_TEAM when using INIT"
  exit 1
fi

if [ -z "$PG_HOST" ]
then
  echo "$0: you need to set PG_HOST to run this script"
  exit 1
fi

if [ -z "$PG_PORT" ]
then
  echo "$0: you need to set PG_PORT to run this script"
  exit 1
fi

if [ ! -z "$AURORA" ]
then
  export PG_ADMIN_USER=sa
fi

# For docker conatiners PG_HOST is 172.17.0.1
export GHA2DB_PROJECTS_YAML="docker/docker_projects.yaml"
export GHA2DB_AFFILIATIONS_JSON="docker/docker_affiliations.json"
export GHA2DB_ES_URL="http://${PG_HOST}:19200"
export GHA2DB_USE_ES=1
export GHA2DB_USE_ES_RAW=1
export LIST_FN_PREFIX="docker/all_"

if [ ! -z "$INIT" ]
then
  ./devel/init_database.sh || exit 1
fi

PROJ=lfn                    PROJDB=lfn                    PROJREPO="iovisor/bcc"                     ORGNAME="Linux Foundation Networking" PORT=3001 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 GHA2DB_SKIP_METRICS="projects_health" GHA2DB_EXCLUDE_VARS="projects_health_partial_html" ./devel/deploy_proj.sh || exit 2
PROJ=iovisor                PROJDB=iovisor                PROJREPO="iovisor/bcc"                     ORGNAME="IO Visor"                    PORT=3002 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 3
PROJ=mininet                PROJDB=mininet                PROJREPO="mininet/mininet"                 ORGNAME="Mininet"                     PORT=3003 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 4
PROJ=opennetworkinglab      PROJDB=opennetworkinglab      PROJREPO="opennetworkinglab/onos"          ORGNAME="Open Networking Laboratory"  PORT=3004 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 5
PROJ=opensecuritycontroller PROJDB=opensecuritycontroller PROJREPO="opensecuritycontroller/osc-core" ORGNAME="Open Security Controller"    PORT=3005 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 6
PROJ=openswitch             PROJDB=openswitch             PROJREPO="open-switch/opx-nas-interface"   ORGNAME="OpenSwitch"                  PORT=3006 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 7
PROJ=p4lang                 PROJDB=p4lang                 PROJREPO="p4lang/p4c"                      ORGNAME="P4 Language"                 PORT=3007 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 8
PROJ=openbmp                PROJDB=openbmp                PROJREPO="OpenBMP/openbmp"                 ORGNAME="OpenBMP"                     PORT=3008 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 9
PROJ=tungstenfabric         PROJDB=tungstenfabric         PROJREPO="tungstenfabric/website"          ORGNAME="Tungsten Fabric"             PORT=3009 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 10
PROJ=cord                   PROJDB=cord                   PROJREPO="opencord/voltha"                 ORGNAME="CORD"                        PORT=3010 ICON="-" GRAFSUFF="-" GA="-" SKIPGRAFANA=1 ./devel/deploy_proj.sh || exit 11

if [ -z "$SKIPVARS" ]
then
  GHA2DB_EXCLUDE_VARS="projects_health_partial_html" ./devel/vars_all.sh || exit 12
fi
echo "$0: All deployments finished"
