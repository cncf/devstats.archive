#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
./util_sh/contributors_and_emails.sh || exit 2
./util_sh/contributing_actors.sh || exit 3
./util_sh/contributing_actors_data.sh || exit 4
./util_sh/k8s_contributors_and_emails.sh || exit 5
./util_sh/top_50_k8s_yearly_contributors.sh || exit 6
./util_sh/k8s_yearly_contributors_with_50.sh || exit 7
echo 'OK'
