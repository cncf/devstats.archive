#!/bin/bash
res=`kubectl get po --all-namespaces | grep calico | grep Running`
if [ -z "$res" ]
then
  echo "calico is not running"
  exit 1
fi
res=`kubectl get po --all-namespaces | grep calico | grep -v Running`
if [ ! -z "$res" ]
then
  echo "some or all calico pods are not in the running state"
  echo "$res"
  exit 2
fi
exit 0
