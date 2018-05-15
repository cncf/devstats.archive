#!/bin/bash
rm grafana.k8s.db*
find . -iname "*.was" -exec rm -f "{}" \;
