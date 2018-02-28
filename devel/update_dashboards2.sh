#!/bin/sh
for f in `ls grafana/dashboards/{cncf,cni,containerd,coredns,envoy,fluentd,grpc,jaeger,linkerd,notary,opencontainers,opentracing,rkt,rook,tuf,vitess}/*`
do
  MODE=rs0 FROM='(?m)^.*"uid": "\w+",\n' TO='-' ./replacer $f
done
