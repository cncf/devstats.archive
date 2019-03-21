#!/bin/bash
if ( [ -z "${SRC}" ] || [ -z "${FILE}" ] || [ -z "${ONLY}" ] )
then
  echo "You need to set ONLY, SRC, FILE environment variables to run this script"
  echo 'ONLY="proj1 proj2" SRC="proj3" FILE="filename.json" $0'
  exit 2
fi
for proj in $ONLY
do
    db=$proj
    cp grafana/dashboards/$SRC/$FILE grafana/dashboards/$proj/$FILE || exit 3
    FROM="\"$SRC\"" TO="\"$proj\"" MODE=ss0 replacer grafana/dashboards/$proj/$FILE || exit 4
done
echo 'OK'

