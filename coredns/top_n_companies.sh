#!/bin/sh
PG_DB=coredns ./runq metrics/coredns/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
