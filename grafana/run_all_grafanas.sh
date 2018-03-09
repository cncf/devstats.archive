#!/bin/bash
for f in ./grafana/*/docker_grafana_run.sh; do ./$f; done
