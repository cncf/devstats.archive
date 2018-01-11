#!/bin/sh
PG_DB=gha ./kubernetes/setup_scripts.sh
PG_DB=prometheus ./prometheus/setup_scripts.sh
PG_DB=opentracing ./opentracing/setup_scripts.sh
PG_DB=fluentd ./fluentd/setup_scripts.sh
PG_DB=linkerd ./linkerd/setup_scripts.sh
PG_DB=grpc ./grpc/setup_scripts.sh
PG_DB=coredns ./coredns/setup_scripts.sh
PG_DB=containerd ./containerd/setup_scripts.sh
