#!/bin/bash
date
cd /root/k8s/devstats || exit 1
git pull || exit 2
./devel/backup_from_openebs.sh || exit 3
echo 'OK'
