#!/bin/bash
set -o pipefail
date > /tmp/gha2db_sync.err
date > /tmp/gha2db_sync.log
gha2db_sync 'kubernetes,kubernetes-client,kubernetes-incubator' 2>> /tmp/gha2db_sync.err | tee -a /tmp/gha2db_sync.log
