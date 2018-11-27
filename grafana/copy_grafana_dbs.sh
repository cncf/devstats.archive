#!/bin/bash
. ./devel/all_projs.sh || exit 2
all=${all/kubernetes/k8s}
for proj in $all
do
    echo $proj
    cp "/var/lib/grafana.${proj}/grafana.db" "/var/www/html/grafana.${proj}.db" || exit 1
    chmod ugo+r "/var/www/html/grafana.${proj}.db" || exit 2
done
echo 'OK'
