#!/bin/bash
rm -f devstats.tar 2>/dev/null
tar cf devstats.tar cmd git metrics docker devel util_sql all lfn shared iovisor mininet opennetworkinglab opensecuritycontroller openswitch p4lang openbmp tungstenfabric cord scripts partials docs cron vendor util_sh/touch *.go projects.yaml github_users.json Makefile
docker build -t devstats .
rm -f devstats.tar
