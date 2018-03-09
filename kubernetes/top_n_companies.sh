#!/bin/bash
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq metrics/kubernetes/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
