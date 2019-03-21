#!/bin/bash
for f in `ls grafana/dashboards/{all,cncf,cni,containerd,coredns,envoy,fluentd,grpc,jaeger,linkerd,kubernetes,notary,opencontainers,opentracing,prometheus,rkt,rook,tuf,vitess}/*`
do
  MODE=rs0 FROM='(?m)^.*"uid": "\w+",\n' TO='-' replacer $f
done

repl='  "timezone": "",'
all="all cncf cni containerd coredns envoy fluentd grpc jaeger linkerd kubernetes notary opencontainers opentracing prometheus rkt rook tuf vitess"
for proj in $all
do
  uid=0
  for f in `ls grafana/dashboards/${proj}/*.json`
  do
    uid=$((uid+1))
    echo "$repl" > out
    echo "  \"uid\": \"$uid\"," >> out
    MODE=ss FROM=$repl TO=`cat out` replacer $f
  done
done
