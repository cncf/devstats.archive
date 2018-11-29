#!/bin/bash
mkdir /data 2>/dev/null
mkdir /data/psql 2>/dev/null
docker run -v /data/psql:/var/lib/postgresql -it postgres:11 /bin/bash
