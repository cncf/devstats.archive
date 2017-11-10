#!/bin/sh
echo 'Bash into running container'
sudo docker exec -i -t `docker ps | grep 'grafana/grafana' | cut -f 1 -d ' '` /bin/bash
