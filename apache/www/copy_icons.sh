#!/bin/sh
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
#convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.png -resize 80x80  /var/www/html/img/kubernetes-icon-noborder-color.png || exit 1
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-color.png -resize 80x80  /var/www/html/img/kubernetes-icon-color.png || exit 1
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 80x80  /var/www/html/img/prometheus-icon-color.png || exit 2
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 80x80  /var/www/html/img/opentracing-icon-color.png || exit 3
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 80x80  /var/www/html/img/fluentd-icon-color.png || exit 4
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 80x80  /var/www/html/img/linkerd-icon-color.png || exit 5
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 80x80  /var/www/html/img/grpc-icon-color.png || exit 6
convert ~/dev/cncf/artwork/coredns/icon/color/coredns-icon-color.png -resize 80x80  /var/www/html/img/core-dns-icon-color.png || exit 7
convert ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.png -resize 80x80  /var/www/html/img/containerd-icon-color.png || exit 8
convert ~/dev/cncf/artwork/rkt/icon/color/rkt-icon-color.png -resize 80x80  /var/www/html/img/rkt-icon-color.png || exit 9
convert ~/dev/cncf/artwork/cni/icon/color/cni-icon-color.png -resize 80x80  /var/www/html/img/cni-icon-color.png || exit 10
convert ~/dev/cncf/artwork/envoy/icon/color/envoy-icon-color.png -resize 80x80  /var/www/html/img/envoy-icon-color.png || exit 11
convert ~/dev/cncf/artwork/jaeger/icon/reverse-color/jaeger-icon-reverse-color.png -resize 80x80  /var/www/html/img/jaeger-icon-color.png || exit 12
convert ~/dev/cncf/artwork/notary/icon/white/notary-icon-white.png -resize 80x80  /var/www/html/img/notary-icon-color.png || exit 13
convert ~/dev/cncf/artwork/tuf/icon/white/tuf-icon-white.png -resize 80x80  /var/www/html/img/tuf-icon-color.png || exit 14
convert ~/dev/cncf/artwork/rook/icon/color/rook-icon-color.png -resize 80x80  /var/www/html/img/rook-icon-color.png || exit 15
convert ~/dev/cncf/artwork/vitess/icon/color/vitess-icon-color.png -resize 80x80  /var/www/html/img/vitess-icon-color.png || exit 16
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 80x80 /var/www/html/img/all-icon-color.png || exit 17
convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 80x80 /var/www/html/img/cncf-icon-color.png || exit 18
echo 'OK'
