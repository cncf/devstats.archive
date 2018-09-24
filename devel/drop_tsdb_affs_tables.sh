#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi
proj=$1
# snum_stats scompany_activity shcom* shpr_comps* ssex ssexcum scountries scountriescum
sudo -u postgres psql $proj -c "drop table snum_stats" || exit 1
sudo -u postgres psql $proj -c "drop table scompany_activity" || exit 2
sudo -u postgres psql $proj -c "drop table ssex" || exit 3
sudo -u postgres psql $proj -c "drop table ssexcum" || exit 4
sudo -u postgres psql $proj -c "drop table scountries" || exit 5
sudo -u postgres psql $proj -c "drop table scountriescum" || exit 6
sudo -u postgres psql $proj -c "drop table stz" || exit 7
tables=`sudo -u postgres psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  base1=${table:0:5}
  base2=${table:0:10}
  if ( [ "$base1" = "shcom" ] || [ "$base2" = "shpr_comps" ] )
  then
    sudo -u postgres psql $proj -c "drop table \"$table\"" || exit 8
    echo "dropped $table"
  fi
done
