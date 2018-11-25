#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi

./devel/drop_ts_tables_staring_with.sh "$1" "scompany_activity"
./devel/drop_ts_tables_staring_with.sh "$1" "snum_stats"
./devel/drop_ts_tables_staring_with.sh "$1" "shcom"
./devel/drop_ts_tables_staring_with.sh "$1" "ssex"
./devel/drop_ts_tables_staring_with.sh "$1" "scountries"
./devel/drop_ts_tables_staring_with.sh "$1" "stz"
./devel/drop_ts_tables_staring_with.sh "$1" "ttz_offsets"
./devel/drop_ts_tables_staring_with.sh "$1" "tcompanies"
./devel/drop_ts_tables_staring_with.sh "$1" "tcountries"

if [ ! "$1" = "gha" ]
then
  ./devel/drop_ts_tables_staring_with.sh "$1" "shpr_comps"
fi
