#!/bin/bash
rm grafana.*.db*
find . -iname "*.was" -exec rm -f "{}" \;
