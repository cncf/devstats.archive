#!/bin/bash
echo "created" > created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2018-10-01 {{to}} 2018-11-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2018-11-01 {{to}} 2018-12-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2018-12-01 {{to}} 2019-01-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-01-01 {{to}} 2019-02-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-02-01 {{to}} 2019-03-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-03-01 {{to}} 2019-04-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-04-01 {{to}} 2019-05-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-05-01 {{to}} 2019-06-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-06-01 {{to}} 2019-07-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-07-01 {{to}} 2019-08-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-08-01 {{to}} 2019-09-01; tail -n 1 out.csv >> created.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} created {{from}} 2019-09-01 {{to}} 2019-10-01; tail -n 1 out.csv >> created.csv
cat created.csv
echo "merged" > merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2018-10-01 {{to}} 2018-11-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2018-11-01 {{to}} 2018-12-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2018-12-01 {{to}} 2019-01-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-01-01 {{to}} 2019-02-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-02-01 {{to}} 2019-03-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-03-01 {{to}} 2019-04-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-04-01 {{to}} 2019-05-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-05-01 {{to}} 2019-06-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-06-01 {{to}} 2019-07-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-07-01 {{to}} 2019-08-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-08-01 {{to}} 2019-09-01; tail -n 1 out.csv >> merged.csv
GHA2DB_CSVOUT=out.csv GHA2DB_LOCAL=1 runq util_sql/count_prs_by_date.sql {{repo}} 'kubernetes/kubernetes' {{what}} merged {{from}} 2019-09-01 {{to}} 2019-10-01; tail -n 1 out.csv >> merged.csv
cat merged.csv
