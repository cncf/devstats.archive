#!/bin/bash
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.png -resize 80x80 /var/www/html/img/kubernetes-icon-color.png || exit 1
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 80x80 /var/www/html/img/prometheus-icon-color.png || exit 2
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 80x80 /var/www/html/img/opentracing-icon-color.png || exit 3
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 80x80 /var/www/html/img/fluentd-icon-color.png || exit 4
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 80x80 /var/www/html/img/linkerd-icon-color.png || exit 5
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 80x80 /var/www/html/img/grpc-icon-color.png || exit 6
convert ~/dev/cncf/artwork/coredns/icon/color/coredns-icon-color.png -resize 80x80 /var/www/html/img/core-dns-icon-color.png || exit 7
convert ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.png -resize 80x80 /var/www/html/img/containerd-icon-color.png || exit 8
convert ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.png -resize 80x80 /var/www/html/img/rkt-icon-color.png || exit 9
convert ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.png -resize 80x80 /var/www/html/img/cni-icon-color.png || exit 10
convert ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.png -resize 80x80 /var/www/html/img/envoy-icon-color.png || exit 11
convert ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.png -resize 80x80 /var/www/html/img/jaeger-icon-color.png || exit 12
convert ~/dev/cncf/artwork/notary/icon/white/notary-icon-white.png -resize 80x80 /var/www/html/img/notary-icon-color.png || exit 13
convert ~/dev/cncf/artwork/tuf/icon/white/tuf-icon-white.png -resize 80x80 /var/www/html/img/tuf-icon-color.png || exit 14
convert ~/dev/cncf/artwork/rook/icon/color/rook-icon-color.png -resize 80x80 /var/www/html/img/rook-icon-color.png || exit 15
convert ~/dev/cncf/artwork/vitess/icon/color/vitess-icon-color.png -resize 80x80 /var/www/html/img/vitess-icon-color.png || exit 16
convert ~/dev/cncf/artwork/nats/icon/color/nats-icon-color.png -resize 80x80 /var/www/html/img/nats-icon-color.png || exit 17
convert ./images/OCI.png -resize 80x80 /var/www/html/img/opencontainers-icon-color.png || exit 18
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 80x80 /var/www/html/img/all-icon-color.png || exit 19
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 80x80 /var/www/html/img/cncf-icon-color.png || exit 20
cp ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.svg /var/www/html/img/kubernetes-icon-color.svg || exit 21
cp ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.svg /var/www/html/img/prometheus-icon-color.svg || exit 22
cp ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.svg /var/www/html/img/opentracing-icon-color.svg || exit 23
cp ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.svg /var/www/html/img/fluentd-icon-color.svg || exit 24
cp ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.svg /var/www/html/img/linkerd-icon-color.svg || exit 25
cp ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.svg /var/www/html/img/grpc-icon-color.svg || exit 26
cp ~/dev/cncf/artwork/coredns/icon/color/coredns-icon-color.svg /var/www/html/img/core-dns-icon-color.svg || exit 27
cp ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.svg /var/www/html/img/containerd-icon-color.svg || exit 28
cp ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.svg /var/www/html/img/rkt-icon-color.svg || exit 29
cp ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.svg /var/www/html/img/cni-icon-color.svg || exit 30
cp ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.svg /var/www/html/img/envoy-icon-color.svg || exit 31
cp ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.svg /var/www/html/img/jaeger-icon-color.svg || exit 32
cp ~/dev/cncf/artwork/notary/icon/white/notary-icon-white.svg /var/www/html/img/notary-icon-color.svg || exit 33
cp ~/dev/cncf/artwork/tuf/icon/white/tuf-icon-white.svg /var/www/html/img/tuf-icon-color.svg || exit 34
cp ~/dev/cncf/artwork/rook/icon/color/rook-icon-color.svg /var/www/html/img/rook-icon-color.svg || exit 35
cp ~/dev/cncf/artwork/vitess/icon/color/vitess-icon-color.svg /var/www/html/img/vitess-icon-color.svg || exit 36
cp ~/dev/cncf/artwork/nats/icon/color/nats-icon-color.svg /var/www/html/img/nats-icon-color.svg || exit 37
cp ./images/OCI.svg /var/www/html/img/opencontainers-icon-color.svg || exit 38
cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg /var/www/html/img/all-icon-color.svg || exit 39
cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.svg /var/www/html/img/cncf-icon-color.svg || exit 40
echo 'OK'
