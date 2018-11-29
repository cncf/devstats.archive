#!/bin/bash
mkdir /data 2>/dev/null
mkdir /data/devstats 2>/dev/null
mkdir /data/psql 2>/dev/null
mkdir /data/es 2>/dev/null && chown 1000:1000 /data/es 2>/dev/null
