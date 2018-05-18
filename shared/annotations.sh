#!/bin/bash
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_PASS env variables to use this script"
  exit 1
fi
GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 ./annotations
