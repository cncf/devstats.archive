#!/bin/sh
./runq metrics/prometheus/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
