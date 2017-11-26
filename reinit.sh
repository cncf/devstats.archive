#!/bin/sh
./kubernetes/reinit_all.sh
./prometheus/reinit.sh
./opentracing/reinit.sh
./fluentd/reinit.sh
./linkerd/reinit.sh
./grpc/reinit.sh
