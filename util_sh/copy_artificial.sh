#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
rm -f /tmp/gha_*.csv || exit -1
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "copy (select * from gha_events where id > 281474976710656) TO '/tmp/gha_events.csv'" || exit 1
mv /tmp/gha_events.csv gha_events.csv || exit 2
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "copy (select * from gha_payloads where event_id > 281474976710656) TO '/tmp/gha_payloads.csv'" || exit 3
mv /tmp/gha_payloads.csv gha_payloads.csv || exit 4
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "copy (select * from gha_issues where event_id > 281474976710656) TO '/tmp/gha_issues.csv'" || exit 5
mv /tmp/gha_issues.csv gha_issues.csv || exit 6
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "copy (select * from gha_issues_labels where event_id > 281474976710656) TO '/tmp/gha_issues_labels.csv'" || exit 7
mv /tmp/gha_issues_labels.csv gha_issues_labels.csv || exit 8
