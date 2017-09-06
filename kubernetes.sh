#!/bin/sh
./structure || exit 1
./gha2db 2015-08-01 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator' || exit 2
GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2015-09-01 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' || exit 3
GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-06-01 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' || exit 4
GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure || exit 5
echo "All done."
