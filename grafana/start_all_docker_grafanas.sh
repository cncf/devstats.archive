#!/bin/bash
for f in ./grafana/*/docker_grafana_start.sh; do ./$f; done
