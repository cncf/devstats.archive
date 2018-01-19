#!/bin/sh
PG_DB=containerd ./runq metrics/containerd/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
