#!/bin/sh
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
cp ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.svg grafana/img/k8s.svg || exit 1
cp ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.svg grafana/img/prometheus.svg || exit 2
cp ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.svg grafana/img/opentracing.svg || exit 3
cp ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.svg grafana/img/fluentd.svg || exit 4
cp ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.svg grafana/img/linkerd.svg || exit 5
cp ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.svg grafana/img/grpc.svg || exit 6
cp ~/dev/cncf/artwork/coredns/icon/color/core-dns-icon-color.svg grafana/img/coredns.svg || exit 7
cp ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.svg grafana/img/containerd.svg || exit 8
cp ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.svg grafana/img/rkt.svg || exit 9
cp ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.svg grafana/img/cni.svg || exit 10
cp ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.svg grafana/img/envoy.svg || exit 11
cp ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.svg grafana/img/jaeger.svg || exit 12
# cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg grafana/img/cncf.svg || exit 13
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.png -resize 32x32 grafana/img/k8s32.png || exit 14
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 32x32 grafana/img/prometheus32.png || exit 15
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 32x32 grafana/img/opentracing32.png || exit 16
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 32x32 grafana/img/fluentd32.png || exit 17
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 32x32 grafana/img/linkerd32.png || exit 18
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 32x32 grafana/img/grpc32.png || exit 19
convert ~/dev/cncf/artwork/coredns/icon/color/core-dns-icon-color.png -resize 32x32 grafana/img/coredns32.png || exit 20
convert ~/dev/cncf/artwork/containerd/icon/color/containerd-icon-color.png -resize 32x32 grafana/img/containerd32.png || exit 21
convert ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.png -resize 32x32 grafana/img/rkt32.png || exit 22
convert ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.png -resize 32x32 grafana/img/cni32.png || exit 23
convert ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.png -resize 32x32 grafana/img/envoy32.png || exit 24
convert ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.png -resize 32x32 grafana/img/jaeger32.png || exit 25
# convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 32x32 grafana/img/cncf32.png || exit 26
echo 'OK'
