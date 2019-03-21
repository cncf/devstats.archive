if [ -z "${GHA2DB_PROJECT}" ]
then
  echo "You need to set GHA2DB_PROJECT environment variable to run this script"
  exit 1
fi
./devel/drop_ts_tables.sh test || exit 2
GHA2DB_LOCAL=1 GHA2DB_DEBUG=1 PG_DB=test annotations
