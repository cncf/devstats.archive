#!/bin/sh
# This script assumes that You have cncf/artwork cloned in ~/dev/cncf/artwork 
cp ~/dev/cncf/artwork/kubernetes/icon/color/kubernetes-icon-noborder-color.png /var/www/html/img/ || exit 1
cp ~/dev/cncf/artwork/prometheus/icon/color/prometheus-icon-color.png /var/www/html/img/ || exit 2
cp ~/dev/cncf/artwork/opentracing/icon/color/opentracing-icon-color.png /var/www/html/img/ || exit 3
cp ~/dev/cncf/artwork/fluentd/icon/color/fluentd-icon-color.png /var/www/html/img/ || exit 4
cp ~/dev/cncf/artwork/linkerd/icon/color/linkerd-icon-color.png /var/www/html/img/ || exit 5
cp ~/dev/cncf/artwork/grpc/icon/color/grpc-icon-color.png /var/www/html/img/ || exit 6
cp ~/dev/cncf/artwork/cncf/icon/color/cncf-icon-color.png /var/www/html/img/ || exit 7
echo 'OK'
