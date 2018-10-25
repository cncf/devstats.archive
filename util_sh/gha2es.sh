#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_USE_ES=1 GHA2DB_PROJECT=cncf PG_DB=cncf ./gha2es 2018-06-01 4 today now
