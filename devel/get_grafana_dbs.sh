#!/bin/bash
. ./devel/all_projs.sh || exit 2
all=${all/kubernetes/k8s}
if [ -z "$ONLY" ]
then
  killall grafana-server 2>/dev/null
fi
for proj in $all
do
    if [ ! -z "$ONLY" ]
    then
      kill `ps -aux | grep grafana-server | grep $proj | awk '{print $2}'`
    fi
    echo "wget grafana.$proj.db"
    rm -f grafana.$proj.db 2>/dev/null
    wget https://teststats.cncf.io/grafana.$proj.db || exit 1
    ls -l grafana.$proj.db
    mv grafana.$proj.db /var/lib/grafana.$proj/grafana.db || exit 2
done
./grafana/start_all_grafanas.sh || exit 3
sleep 5
ps -aux | grep 'grafana-server'
echo 'OK'

