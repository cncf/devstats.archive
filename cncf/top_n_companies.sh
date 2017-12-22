#!/bin/sh
PG_DB=cncf ./runq metrics/cncf/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
