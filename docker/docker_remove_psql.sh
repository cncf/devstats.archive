#!/bin/bash
psql_img=`docker container ls | awk '/postgres:11/{print $1}'`
docker container stop "${psql_img}" && docker container rm "${psql_img}"
