#!/bin/bash
PG_DB=allprj GHA2DB_LOCAL=1 ../devstatscode/calc_metric xyz util_sql/all_placeholders.sql '2020-03-13 10' '2020-03-13 11' a_1_n 'project_scale:2,hist,annotations_ranges'
