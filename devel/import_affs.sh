#!/bin/sh
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 2
fi
./kubernetes/import_affs.sh || exit 3
./prometheus/import_affs.sh || exit 4
./opentracing/import_affs.sh || exit 5
./fluentd/import_affs.sh || exit 6
./linkerd/import_affs.sh || exit 7
./grpc/import_affs.sh || exit 8
./coredns/import_affs.sh || exit 9
./containerd/import_affs.sh || exit 10
./rkt/import_affs.sh || exit 11
./cni/import_affs.sh || exit 12
./envoy/import_affs.sh || exit 13
./jaeger/import_affs.sh || exit 14
./notary/import_affs.sh || exit 15
./tuf/import_affs.sh || exit 16
./rook/import_affs.sh || exit 17
# ./cncf/import_affs.sh || exit 18
./kubernetes/top_n_companies.sh 70 >> ./metrics/kubernetes/gaps.yaml
./prometheus/top_n_companies.sh 70 >> ./metrics/prometheus/gaps.yaml
./opentracing/top_n_companies.sh 70 >> ./metrics/opentracing/gaps.yaml
./fluentd/top_n_companies.sh 70 >> ./metrics/fluentd/gaps.yaml
./linkerd/top_n_companies.sh 70 >> ./metrics/linkerd/gaps.yaml
./grpc/top_n_companies.sh 70 >> ./metrics/grpc/gaps.yaml
./coredns/top_n_companies.sh 70 >> ./metrics/coredns/gaps.yaml
./containerd/top_n_companies.sh 70 >> ./metrics/containerd/gaps.yaml
./rkt/top_n_companies.sh 70 >> ./metrics/rkt/gaps.yaml
./cni/top_n_companies.sh 70 >> ./metrics/cni/gaps.yaml
./envoy/top_n_companies.sh 70 >> ./metrics/envoy/gaps.yaml
./jaeger/top_n_companies.sh 70 >> ./metrics/jaeger/gaps.yaml
./notary/top_n_companies.sh 70 >> ./metrics/notary/gaps.yaml
./tuf/top_n_companies.sh 70 >> ./metrics/tuf/gaps.yaml
./rook/top_n_companies.sh 70 >> ./metrics/rook/gaps.yaml
# ./cncf/top_n_companies.sh 70 >> ./metrics/cncf/gaps.yaml
echo 'OK'
