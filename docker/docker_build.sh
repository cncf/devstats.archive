#!/bin/bash
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics docker devel util_sql all buildpacks shared scripts vendor util_sh/touch docs/touch partials/touch cron/net_tcp_config.sh *.go projects.yaml Makefile
docker build -t devstats .
rm -f devstats.tar
