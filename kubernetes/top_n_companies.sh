#!/bin/sh
./runq metrics/kubernetes/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
