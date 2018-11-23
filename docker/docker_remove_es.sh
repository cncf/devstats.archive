#!/bin/bash
es_img=`docker container ls | awk '/elasticsearch:6.5.1/{print $1}'`
docker container stop "${es_img}" && docker container rm "${es_img}"
