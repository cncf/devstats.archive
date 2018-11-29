#!/bin/bash
./docker/docker_remove_psql.sh
./docker/docker_remove_es.sh
./docker/docker_remove.sh
docker system prune
