#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 runq util_sql/count_all_tables.sql
