#!/bin/sh
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork and imagemagick installed
convert ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-noborder-color.png -resize 80x80  /var/www/html/img/kubernetes-icon-noborder-color.png || exit 1
convert ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png -resize 80x80  /var/www/html/img/prometheus-icon-color.png || exit 2
convert ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png -resize 80x80  /var/www/html/img/opentracing-icon-color.png || exit 3
convert ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png -resize 80x80  /var/www/html/img/fluentd-icon-color.png || exit 4
convert ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png -resize 80x80  /var/www/html/img/linkerd-icon-color.png || exit 5
convert ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png -resize 80x80  /var/www/html/img/grpc-icon-color.png || exit 6
convert ~/dev/cncf/artwork/coredns/icon/color/core-dns-icon-color.png -resize 80x80  /var/www/html/img/core-dns-icon-color.png || exit 7
convert ~/dev/cncf/artwork/containerd/icon/white/containerd-icon-white.png -resize 80x80  /var/www/html/img/containerd-icon-color.png || exit 8
# convert ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png -resize 80x80 /var/www/html/img/cncf-icon-color.png || exit 9
echo 'OK'
