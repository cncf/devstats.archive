#!/bin/bash
cronctl.sh devstats on || exit 1
cronctl.sh webhook on || exit 2
echo 'All sync and deploy jobs enabled'
