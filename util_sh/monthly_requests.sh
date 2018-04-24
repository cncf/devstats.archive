#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
./util_sh/monthly.sh '2014-01-01' false "'Google'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id google_contributors.csv
./util_sh/monthly.sh '2014-01-01' false "'Google'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id google_contributions.csv
./util_sh/monthly.sh '2014-01-01' false "'Google'" "'PushEvent'" actor_id google_committers.csv
./util_sh/monthly.sh '2014-01-01' false "'Google'" "'PushEvent'" id google_commits.csv
./util_sh/monthly.sh '2014-01-01' false "'Red Hat'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id red_hat_contributors.csv
./util_sh/monthly.sh '2014-01-01' false "'Red Hat'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id red_hat_contributions.csv
./util_sh/monthly.sh '2014-01-01' false "'Red Hat'" "'PushEvent'" actor_id red_hat_committers.csv
./util_sh/monthly.sh '2014-01-01' false "'Red Hat'" "'PushEvent'" id red_hat_commits.csv
./util_sh/monthly.sh '2014-01-01' false "'Independent'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id independent_contributors.csv
./util_sh/monthly.sh '2014-01-01' false "'Independent'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id independent_contributions.csv
./util_sh/monthly.sh '2014-01-01' false "'Independent'" "'PushEvent'" actor_id independent_committers.csv
./util_sh/monthly.sh '2014-01-01' false "'Independent'" "'PushEvent'" id independent_commits.csv
./util_sh/monthly.sh '2014-01-01' false "'Microsoft'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id microsoft_contributors.csv
./util_sh/monthly.sh '2014-01-01' false "'Microsoft'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id microsoft_contributions.csv
./util_sh/monthly.sh '2014-01-01' false "'Microsoft'" "'PushEvent'" actor_id microsoft_committers.csv
./util_sh/monthly.sh '2014-01-01' false "'Microsoft'" "'PushEvent'" id microsoft_commits.csv
