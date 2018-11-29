#!/bin/bash
mkdir /data 2>/dev/null
mkdir /data/psql 2>/dev/null
docker run --mount src="/data/psql",target="/var/lib/postgresql/data",type=bind -it postgres:11 /bin/bash
