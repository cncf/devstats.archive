#!/bin/sh
echo "Killing all containers"
service docker stop
service docker start
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)
exit 0
