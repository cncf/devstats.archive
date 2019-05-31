#!/bin/bash
cd ..
for f in devstats devstatscode devstats-docker-images devstats-docker-lf devstats-example devstats-helm devstats-helm-lf devstats-k8s-lf devstats-reports devstats-helm-example devstats-helm-graphql devstats-kubernetes-dashboard json2hat-helm
do
  cd $f
  echo ">>>>> status: $f <<<<<"
  git status
  cd ..
done
