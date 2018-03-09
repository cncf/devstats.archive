#!/bin/bash
GHA2DB_PROJECT=kubernetes IDB_DB=test ./db2influx multi_row_single_column metrics/kubernetes/project_stats.sql '2015-08-03 0' '2017-08-03 1' anno_0_1 hist,annotations_ranges,skip_past
