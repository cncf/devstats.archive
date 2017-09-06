#!/bin/sh
PG_DB=test GHA2DB_MGETC=y ./structure || exit 1
#PG_DB=test ./gha2db 2017-08-29 0 2017-08-31 0 'kubernetes,kubernetes-client,kubernetes-incubator' || exit 2
##echo "Finished 1st phase, press enter or ^c"
##read a
#PG_DB=test GHA2DB_EXACT=1 ./gha2db 2015-07-07 0 2015-07-09 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' || exit 3
##echo "Finished 2nd phase, press enter or ^c"
##read a
PG_DB=test GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-11-04 0 2014-11-06 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' || exit 4
##echo "Finished 3rd phase, press enter or ^c"
##read a
PG_DB=test GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure || exit 5
echo "All done."
