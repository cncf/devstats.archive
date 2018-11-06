#!/bin/bash
killall grafana-server
./grafana/start_all_grafanas.sh
./util_sh/start_contrib.sh
