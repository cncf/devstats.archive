#!/bin/bash
. ./devel/all_projs.sh || exit 2
all=${all/kubernetes/k8s}
if [ -z "$ONLY" ]
then
  killall grafana-server 2>/dev/null
fi
for proj in $all
do
    echo $proj
    if [ ! -z "$ONLY" ]
    then
      kill `ps -aux | grep grafana-server | grep $proj | awk '{print $2}'`
    fi
    rm -rf /usr/share/grafana.$proj
    cp -R /usr/share/grafana /usr/share/grafana.$proj || exit 1
    rm -rf /var/lib/grafana.$proj
    cp -R /var/lib/grafana /var/lib/grafana.$proj || exit 2
done
echo 'OK'
./grafana/change_title_and_icons_all.sh || exit 3
./devel/get_grafana_dbs.sh || exit 4
./grafana/start_all_grafanas.sh || exit 5
sleep 5
ps -aux | grep 'grafana-server'
