#!/bin/bash
# Example `FROM=DS_PROMETHEUS TO=DS_GHA ./devel/mass_update.sh grafana/dashboards/prometheus/*.json`
if [ -z "${FROM}" ]
then
  echo "You need to set FROM, example FROM=abc TO=xyz $0 ./some_dir/*"
  exit 1
fi
if [ -z "${TO}" ]
then
  echo "You need to set TO, example FROM=abc TO=xyz $0 ./some_dir/*"
  exit 2
fi
for f in $*
do
  ls -l "$f"
  vim --not-a-term -c "%s/${FROM}/${TO}/g" -c "wq!" "$f"
done
