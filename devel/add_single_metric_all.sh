#!/bin/sh
GHA2DB_PROJECT=kubernetes ./devel/add_single_metric.sh
GHA2DB_PROJECT=prometheus ./devel/add_single_metric.sh
GHA2DB_PROJECT=opentracing ./devel/add_single_metric.sh
GHA2DB_PROJECT=fluentd ./devel/add_single_metric.sh
GHA2DB_PROJECT=linkerd ./devel/add_single_metric.sh
GHA2DB_PROJECT=grpc ./devel/add_single_metric.sh
