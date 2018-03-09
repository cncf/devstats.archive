if [ -z "$1" ]
then
  echo "You need to provide project name as argument"
  exit 1
fi
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 2
fi
#!/bin/bash
GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 3
PG_DB="allprj" ./devel/remove_db_dups.sh || exit 4
./all/get_repos.sh || exit 5
./all/setup_repo_groups.sh || exit 6
./all/top_n_repos_groups.sh 70 > out
./all/top_n_companies 70 >> out
cat out
echo 'Please update ./metrics/all/gaps*.yaml with new companies & repo groups data.'
echo 'Then run ./all/reinit.sh.'
echo 'Top 70 repo groups & companies are saved in "out" file.'
