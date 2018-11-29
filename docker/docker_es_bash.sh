#!/bin/bash
mkdir /data 2>/dev/null
mkdir /data/es 2>/dev/null
docker run --mount src="/data/es",target="/var/lib/elasticsearch",type=bind -it elasticsearch:6.5.1 /bin/bash
