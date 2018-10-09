#!/bin/bash
if [ -z "$1" ]
then
  echo "You need to provide grafana file url (for example 'https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_5.0.3_amd64.deb')"
  exit 1
fi
bname=`basename "$1"`
if [ ! "$1" = "$bname" ]
then
  wget "$1" || exit 2
fi
rm -rf ~/grafana.v5.old 2>/dev/null
mv ~/grafana.v5 ~/grafana.v5.old 2>/dev/null
mkdir ~/grafana.v5 || exit 3
if [ -z "$ONLY" ]
then
  killall grafana-server 2>/dev/null
fi
sudo dpkg -i `basename "$1"` || exit 4
rm -f `basename "$1"` 2>/dev/null
mv /usr/share/grafana ~/grafana.v5/usr.share.grafana || exit 5
mv /var/lib/grafana ~/grafana.v5/var.lib.grafana || exit 6
mv /etc/grafana ~/grafana.v5/etc.grafana || exit 7
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
for proj in $all
do
    echo $proj
    if [ ! -z "$ONLY" ]
    then
      kill `ps -aux | grep grafana-server | grep $proj | awk '{print $2}'`
    fi
    rm -rf /usr/share/grafana.$proj 2>/dev/null
    cp -R ~/grafana.v5/usr.share.grafana/ /usr/share/grafana.$proj || exit 8
done
./grafana/change_title_and_icons_all.sh || exit 9
./grafana/start_all_grafanas.sh || exit 10
sleep 5
ps -aux | grep 'grafana-server'
echo 'Do: cd ~/cncf/contributors && ./grafana.sh &'
