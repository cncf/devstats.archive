#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide database name as an argument"
  exit 1
fi
db=$1
if [ "$db" = "devstats" ]
then
  exit 0
fi
cd /tmp || exit 1
function finish {
  cd /tmp
  rm $db.*
}
trap finish EXIT
rm -f $db.tar* || exit 2
cp /var/www/html/$db.tar.xz . || exit 3
xz -d $db.tar.xz || exit 4
tar xf $db.tar || exit 5
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_events from '/tmp/$db.events.tsv'" || exit 6
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_payloads from '/tmp/$db.payloads.tsv'" || exit 7
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_issues from '/tmp/$db.issues.tsv'" || exit 8
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_pull_requests from '/tmp/$db.prs.tsv'" || exit 9
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_milestones from '/tmp/$db.milestones.tsv'" || exit 10
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_issues_labels from '/tmp/$db.labels.tsv'" || exit 11
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_issues_assignees from '/tmp/$db.issue_assignees.tsv'" || exit 12
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_pull_requests_assignees from '/tmp/$db.pr_assignees.tsv'" || exit 13
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_pull_requests_requested_reviewers from '/tmp/$db.pr_reviewers.tsv'" || exit 14
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_issues_events_labels from '/tmp/$db.issues_events_labels.tsv'" || exit 15
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" $db -tAc "copy gha_texts from '/tmp/$db.texts.tsv'" || exit 16
