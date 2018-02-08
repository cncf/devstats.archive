#!/bin/sh
wget https://s3-us-west-2.amazonaws.com/grafana-releases/master/grafana_5.0.0-11639beta1_amd64.deb
rm -rf ~/grafana.v5.old
mv ~/grafana.v5 ~/grafana.v5.old
mkdir ~/grafana.v5
killall grafana-server
sudo dpkg -i grafana_5.0.0-11639beta1_amd64.deb
mv /usr/share/grafana ~/grafana.v5/usr.share.grafana
mv /var/lib/grafana ~/grafana.v5/var.lib.grafana
mv /etc/grafana ~/grafana.v5/etc.grafana
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers all cncf"
else
  all="k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess opencontainers"
fi
for proj in $all
do
    echo $proj
    rm -rf /usr/share/grafana.$proj
    cp -R ~/grafana.v5/usr.share.grafana/ /usr/share/grafana.$proj || exit 1
done
echo 'OK'
./grafana/change_title_and_icons_all.sh || exit 3
./grafana/start_all_grafanas.sh || exit 5
sleep 5
ps -aux | grep 'grafana-server'
