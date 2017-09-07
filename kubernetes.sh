#!/bin/bash
set -o pipefail
> errors.txt
> run.log
./structure 2>>errors.txt | tee -a run.log || exit 1
# Next 3 calls takes about: 1h43m, 26m, 17m
./gha2db 2015-08-06 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2015-08-14 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-06-02 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 4
# This generates index and summary tables, it takes 5m32s
GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
echo "All done."
