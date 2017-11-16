#!/bin/sh
# GRAFANA_DATA=/usr/share/grafana.k8s/
for f in `find ${GRAFANA_DATA} -type f -exec grep -l "'Grafana - '" "{}" \; | sort | uniq`
do
  ls -l "$f"
  vim -c "%s/'Grafana - '/'K8s DevStats - '/g|wq" "$f"
done
for f in `find ${GRAFANA_DATA} -type f -exec grep -l '"Grafana - "' "{}" \; | sort | uniq`
do
  ls -l "$f"
  vim -c '%s/"Grafana - "/"K8s DevStats - "/g|wq' "$f"
done
cp -n ${GRAFANA_DATA}/public/img/grafana_icon.svg ${GRAFANA_DATA}/public/img/grafana_icon.svg.bak
cp grafana/img/k8s.svg ${GRAFANA_DATA}/public/img/grafana_icon.svg || exit 1
cp -n ${GRAFANA_DATA}/public/img/fav32.png ${GRAFANA_DATA}/public/img/fav32.png.bak
cp grafana/img/k8s32.png ${GRAFANA_DATA}/public/img/fav32.png || exit 1
cp -n ${GRAFANA_DATA}/public/img/fav16.png ${GRAFANA_DATA}/public/img/fav16.png.bak
cp grafana/img/k8s32.png ${GRAFANA_DATA}/public/img/fav16.png || exit 1
cp -n ${GRAFANA_DATA}/public/img/fav_dark_16.png ${GRAFANA_DATA}/public/img/fav_dark_16.png.bak
cp grafana/img/k8s32.png ${GRAFANA_DATA}/public/img/fav_dark_16.png || exit 1
cp -n ${GRAFANA_DATA}/public/img/fav_dark_32.png ${GRAFANA_DATA}/public/img/fav_dark_32.png.bak
cp grafana/img/k8s32.png ${GRAFANA_DATA}/public/img/fav_dark_32.png || exit 1
echo 'OK'
