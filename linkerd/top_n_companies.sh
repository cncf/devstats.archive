#!/bin/sh
PG_DB=linkerd ./runq metrics/linkerd/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
