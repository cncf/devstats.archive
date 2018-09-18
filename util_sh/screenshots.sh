#!/bin/bash
for f in k8s prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opa spiffe spire opencontainers cloudevents telepresence helm openmetrics harbor etcd tikv cncf all
do
  for srv in cncftest devstats.cncf
  do
    fn="${f}_${srv}.png"
    if ( [ "$fn" = "opencontainers_devstats.cncf.png" ] || [ "$fn" = "cncf_devstats.cncf.png" ] )
    then
      continue
    fi
    if [ -f "$fn" ]
    then
      echo "$fn already exists, skipping"
    else
      if [ "$f" = "k8s" ]
      then
        /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "https://$f.$srv.io/d/8/company-statistics-by-repository-group?orgId=1"
      else
        /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "https://$f.$srv.io/d/4/companies-stats?orgId=1"
      fi
      mv ~/Desktop/Screen* "${f}_${srv}.png" || exit 1
    fi
  done
done
