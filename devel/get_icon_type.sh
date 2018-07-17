#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: requires project name parameter"
  exit 1
fi
declare -A icontypes
icontypes=( 
  ["kubernetes"]="color"
  ["prometheus"]="color"
  ["opentracing"]="color"
  ["fluentd"]="color"
  ["linkerd"]="color"
  ["grpc"]="color"
  ["coredns"]="color"
  ["containerd"]="white"
  ["rkt"]="color"
  ["cni"]="color"
  ["envoy"]="color"
  ["jaeger"]="reverse-color"
  ["notary"]="white"
  ["tuf"]="white"
  ["rook"]="color"
  ["vitess"]="color"
  ["nats"]="color"
  ["opa"]="color"
  ["spiffe"]="color"
  ["spire"]="color"
  ["cncf"]="color"
  ["cloudevents"]="color"
  ["telepresence"]="color"
  ["helm"]="color"
  ["openmetrics"]="color"
  ["harbor"]="color"
  ["all"]="color"
  ["devstats"]="color"
)
icontype=${icontypes[$1]}
if [ -z "$icontype" ]
then
  echo "$0: project $1 is not defined"
  exit 1
fi
echo $icontype
