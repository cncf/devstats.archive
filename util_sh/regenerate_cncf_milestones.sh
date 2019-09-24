#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: PG_PASS environment variable must be set"
  exit 1
fi
GHA2DB_FORCE_PERIODS='c_j_i:t,c_i_g:t,c_g_n:t,c_i_n:t,c_j_g:t' ./util_sh/recalculate_periods_all.sh
