#!/bin/bash
mkdir /data 2>/dev/null
mkdir /data/es 2>/dev/null
docker run -v /data/es:/var/lib/elasticsearch -it elasticsearch:6.5.1 /bin/bash
