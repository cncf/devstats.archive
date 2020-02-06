#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS=..."
  exit 1
fi
export PG_DB=afftest
if [ ! -z "$REINIT" ]
then
  sudo -u postgres psql -c "drop database if exists ${PG_DB}" || exit 2
  GHA2DB_LOCAL=1 GHA2DB_INDEX=1 ../devstatscode/structure || exit 3
fi
GHA2DB_LOCAL=1 runq ./scripts/clean_affiliations.sql || exit 4
GHA2DB_LOCAL=1 ../devstatscode/import_affs ./util_json/test_affs.json || exit 5
sudo -u postgres psql $PG_DB -c "update gha_actors set id = (select id from gha_actors where login = 'lukaszgryglicki') where login = 'lgryglicki'"
sudo -u postgres psql $PG_DB -c "update gha_actors set id = (select id from gha_actors where login = 'other2') where login = 'other'"
sudo -u postgres psql $PG_DB -c "update gha_actors set id = (select id from gha_actors where login = 'aother') where login = 'aother2'"
sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select -id/112, login, name, country_id, sex, sex_prob, tz, country_name, age from gha_actors where login = 'lukaszgryglicki'"
sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select -id/997, login, name, country_id, sex, sex_prob, tz, country_name, age from gha_actors where login = 'lgryglicki'"
sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select id, 'other3', name, country_id, sex, sex_prob, tz, country_name, age from gha_actors where login = 'other2'"
sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select id, 'aother3', name, country_id, sex, sex_prob, tz, country_name, age from gha_actors where login = 'aother'"
sudo -u postgres psql $PG_DB -c "update gha_actors set id = 1982 where lower(login) like 'src%'"
GHA2DB_LOCAL=1 runq ./scripts/clean_affiliations.sql || exit 4
GHA2DB_LOCAL=1 ../devstatscode/import_affs ./util_json/test_affs.json || exit 5
#sudo -u postgres psql $PG_DB -c 'insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select -id, login, name, country_id, sex, sex_prob, tz, country_name, age from gha_actors'
#sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select id, 'alt-' || login, name, country_id, sex, sex_prob, tz, country_name, age from gha_actors"
#sudo -u postgres psql $PG_DB -c "insert into gha_actors(id, login, name, country_id, sex, sex_prob, tz, country_name, age) select -id, 'alt2-' || login, name, country_id, sex, sex_prob, tz, country_name, age from gha_actors"
sudo -u postgres psql $PG_DB
