#!/bin/bash
INIT=1 GHA2DB_GHAPISKIP=1 SKIPTEMP=1 PG_HOST=127.0.0.1 PG_PORT=65432 ./docker/docker_deploy_all.sh
