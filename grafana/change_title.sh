#!/bin/sh
# GRAFANA_DATA=/usr/share/grafana/
for f in `find ${GRAFANA_DATA} -type f -exec grep -l "Grafana -" "{}" \; | sort | uniq`
do
  ls -l "$f"
  vim -c "%s/Grafana -/K8s DevStats -/g|wq" "$f"
done
