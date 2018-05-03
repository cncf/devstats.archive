#!/bin/bash
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_QOUT=1 GHA2DB_DEBUG=1 ./db2influx multi_row_multi_column metrics/kubernetes/pr_workload_table.sql '2018-05-01' '2018-05-03' anno_29_30 hist,multivalue,annotations_ranges,skip_past
