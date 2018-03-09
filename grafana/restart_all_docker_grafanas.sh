#!/bin/bash
for f in ./grafana/*/docker_grafana_restart.sh; do ./$f; done
