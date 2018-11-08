#!/bin/bash
echo 'Uses devstats runq command to connect to host postgres and display number of texts in the database'
if [ -z "$PG_PASS" ]
then
  if [ -z "$INTERACTIVE" ]
  then
    echo "$0: you need to set PG_PASS=... environment variable"
    exit 1
  else
    echo -n 'Postgres pwd: '
    read -s PG_PASS
    echo ''
  fi
fi
docker run -e GHA2DB_PROJECTS_OVERRIDE="-kubernetes,-prometheus,-opentracing,-fluentd,-linkerd,-grpc,-coredns,-containerd,-rkt,-cni,-envoy,-jaeger,-notary,-tuf,-rook,-vitess,-nats,-opa,-spiffe,-spire,-cloudevents,-telepresence,-helm,-openmetrics,-harbor,-etcd,-tikv,-cortex,-falco,-cncf,-all,-opencontainers,-istio,-spinnaker" -e ONLY=buildpacks -e GHA2DB_GHAPISKIP=1 -e PG_PORT=65432 -e PG_HOST=`docker run -it devstats ip route show | awk '/default/ {print $3}'` -e PG_PASS="${PG_PASS}" -it devstats devstats
