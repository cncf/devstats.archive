#!/bin/bash
echo 'Bash into running kubernetes grafana container'
sudo docker exec -i -t k8s_grafana /bin/bash
