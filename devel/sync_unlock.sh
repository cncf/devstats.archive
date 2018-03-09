#!/bin/bash
cronctl.sh devstats on || exit 2
cronctl.sh webhook on || exit 4
echo 'All sync and deploy jobs enabled'
