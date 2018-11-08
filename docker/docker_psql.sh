#!/bin/bash
docker run -p 65432:5432 postgres:10 1>/tmp/docker.psql.log 2>/tmp/docker.psql.err &
