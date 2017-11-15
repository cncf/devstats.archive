#!/bin/sh
docker inspect $1 | grep IPAddress
