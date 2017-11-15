#!/bin/sh
PG_DB=fluentd ./runq metrics/fluentd/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
