#!/bin/sh
host=`hostname`
if [ $host = "cncftest.io" ]
then
  all="gha prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook allprj cncf"
else
  all="gha prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook"
fi
for proj in $all
do
    echo "wget $proj.sql.xz"
    rm -f $proj.sql.xz 2>/dev/null
    rm -f $proj.sql 2>/dev/null
    wget https://cncftest.io/$proj.sql.xz || exit 1
    ls -l $proj.sql.xz
    echo "xz -d $proj.sql"
    xz -d $proj.sql.xz || exit 2
    echo "restore $proj"
    ls -l $proj.sql
    sudo -u postgres psql -c "drop database $proj" 2> /dev/null
    sudo -u postgres psql -c "create database $proj" || exit 3
    sudo -u postgres psql $proj < $proj.sql || exit 4
    echo "rm -f $proj"
    rm -f $proj.sql || exit 5
done
echo 'OK'

