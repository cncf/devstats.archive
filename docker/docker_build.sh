#!/bin/bash
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics docker devel util_sql all buildpacks shared scripts partials docs vendor util_sh/touch cron/net_tcp_config.sh *.go projects.yaml github_users.json Makefile
docker build -t devstats .
rm -f devstats.tar
