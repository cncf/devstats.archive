#!/bin/sh
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
cp ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-noborder-color.svg grafana/img/k8s.svg || exit 1
cp ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.svg grafana/img/prometheus.svg || exit 2
cp ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.svg grafana/img/opentracing.svg || exit 3
cp ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.svg grafana/img/fluentd.svg || exit 4
cp ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.svg grafana/img/linkerd.svg || exit 5
cp ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.svg grafana/img/grpc.svg || exit 6
cp ~/dev/cncf/artwork/coredns/icon/color/core-dns-icon-color.svg grafana/img/coredns.svg || exit 7
cp ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.svg grafana/img/containerd.svg || exit 8
# cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg grafana/img/cncf.svg || exit 9
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-noborder-color.png -resize 32x32 grafana/img/k8s32.png || exit 10
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 32x32 grafana/img/prometheus32.png || exit 11
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 32x32 grafana/img/opentracing32.png || exit 12
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 32x32 grafana/img/fluentd32.png || exit 13
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 32x32 grafana/img/linkerd32.png || exit 14
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 32x32 grafana/img/grpc32.png || exit 15
convert ~/dev/cncf/artwork/coredns/icon/color/core-dns-icon-color.png -resize 32x32 grafana/img/coredns32.png || exit 16
convert ~/dev/cncf/artwork/containerd/icon/color/containerd-icon-color.png -resize 32x32 grafana/img/containerd32.png || exit 17
# convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 32x32 grafana/img/cncf32.png || exit 18
echo 'OK'
