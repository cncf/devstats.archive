#!/bin/bash
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics util_sql util_sh/touch docs/touch partials/touch scripts cron/net_tcp_config.sh devel/*.txt vendor *.go projects.yaml Makefile
docker build -t devstats .
rm -f devstats.tar
