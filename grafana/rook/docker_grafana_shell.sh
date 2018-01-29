#!/bin/sh
echo 'Bash into running rook grafana container'
sudo docker exec -i -t rook_grafana /bin/bash
