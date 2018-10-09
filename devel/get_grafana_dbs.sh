#!/bin/bash
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi
all=${all/kubernetes/k8s}
killall grafana-server
for proj in $all
do
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

