#!/bin/bash
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
cp ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.svg grafana/img/k8s.svg || exit 1
cp ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.svg grafana/img/prometheus.svg || exit 2
cp ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.svg grafana/img/opentracing.svg || exit 3
cp ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.svg grafana/img/fluentd.svg || exit 4
cp ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.svg grafana/img/linkerd.svg || exit 5
cp ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.svg grafana/img/grpc.svg || exit 6
cp ~/dev/cncf/artwork/coredns/icon/color/coredns-icon-color.svg grafana/img/coredns.svg || exit 7
cp ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.svg grafana/img/containerd.svg || exit 8
cp ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.svg grafana/img/rkt.svg || exit 9
cp ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.svg grafana/img/cni.svg || exit 10
cp ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.svg grafana/img/envoy.svg || exit 11
cp ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.svg grafana/img/jaeger.svg || exit 12
cp ~/dev/cncf/artwork/notary/icon/white/notary-icon-white.svg grafana/img/notary.svg || exit 13
cp ~/dev/cncf/artwork/tuf/icon/white/tuf-icon-white.svg grafana/img/tuf.svg || exit 14
cp ~/dev/cncf/artwork/rook/icon/color/rook-icon-color.svg grafana/img/rook.svg || exit 15
cp ~/dev/cncf/artwork/vitess/icon/color/vitess-icon-color.svg grafana/img/vitess.svg || exit 16
cp ~/dev/cncf/artwork/nats/icon/color/nats-icon-color.svg grafana/img/nats.svg || exit 17
cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg grafana/img/all.svg || exit 18
cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg grafana/img/cncf.svg || exit 19
cp images/OCI.svg grafana/img/opencontainers.svg || exit 20
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.png -resize 32x32 grafana/img/k8s32.png || exit 21
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 32x32 grafana/img/prometheus32.png || exit 22
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 32x32 grafana/img/opentracing32.png || exit 23
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 32x32 grafana/img/fluentd32.png || exit 24
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 32x32 grafana/img/linkerd32.png || exit 25
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 32x32 grafana/img/grpc32.png || exit 26
convert ~/dev/cncf/artwork/coredns/icon/color/coredns-icon-color.png -resize 32x32 grafana/img/coredns32.png || exit 27
convert ~/dev/cncf/artwork/containerd/icon/color/containerd-icon-color.png -resize 32x32 grafana/img/containerd32.png || exit 28
convert ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.png -resize 32x32 grafana/img/rkt32.png || exit 29
convert ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.png -resize 32x32 grafana/img/cni32.png || exit 30
convert ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.png -resize 32x32 grafana/img/envoy32.png || exit 31
convert ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.png -resize 32x32 grafana/img/jaeger32.png || exit 32
convert ~/dev/cncf/artwork/notary/icon/white/notary-icon-white.png -resize 32x32 grafana/img/notary32.png || exit 33
convert ~/dev/cncf/artwork/tuf/icon/white/tuf-icon-white.png -resize 32x32 grafana/img/tuf32.png || exit 34
convert ~/dev/cncf/artwork/rook/icon/color/rook-icon-color.png -resize 32x32 grafana/img/rook32.png || exit 35
convert ~/dev/cncf/artwork/vitess/icon/color/vitess-icon-color.png -resize 32x32 grafana/img/vitess32.png || exit 36
convert ~/dev/cncf/artwork/nats/icon/color/nats-icon-color.png -resize 32x32 grafana/img/nats32.png || exit 37
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 32x32 grafana/img/all32.png || exit 38
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 32x32 grafana/img/cncf32.png || exit 39
convert images/OCI.png -resize 32x32 grafana/img/opencontainers32.png || exit 40
echo 'OK'
