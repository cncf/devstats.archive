#!/bin/bash
cd ..
for f in devstats devstatscode devstats-docker-images devstats-docker-lf devstats-example devstats-helm-lf devstats-k8s-lf json2hat-helm
do
  cd $f
  echo ">>>>> pull: $f <<<<<"
  git pull
  cd ..
done
