#!/bin/sh
PG_DB=opentracing ./runq metrics/opentracing/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
