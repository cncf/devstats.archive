#!/bin/bash
# Run this script from the repository top level: ./kubernetes/kubernetes_pre2015.sh
set -o pipefail
> errors.txt
> run.log
GHA2DB_LOCAL=1 PG_DB=test GHA2DB_MGETC=y structure 2>>errors.txt | tee -a run.log || exit 1
GHA2DB_LOCAL=1 PG_DB=test GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-08-01 0 2014-08-03 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_LOCAL=1 PG_DB=test GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 5
echo "All done."
