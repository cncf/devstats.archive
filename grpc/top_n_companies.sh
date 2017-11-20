#!/bin/sh
PG_DB=grpc ./runq metrics/grpc/companies_tags.sql {{lim}} $1 ' sub.name' " string_agg(sub.name, ',')"
