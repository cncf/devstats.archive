#!/bin/bash
GRAFANA=k8s devel/import_jsons_to_sqlite.sh grafana/dashboards/kubernetes/*.json
