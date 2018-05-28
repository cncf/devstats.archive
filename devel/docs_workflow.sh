#!/bin/bash
ONLY=kubernetes ./devel/vars_all.sh || exit 1
./devel/put_k8s_charts.sh || exit 2
./devel/put_k8s_charts_cleanup.sh || exit 3
