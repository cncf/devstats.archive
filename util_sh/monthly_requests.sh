#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to specify PG_PASS env variable"
  exit 1
fi
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id google_contributors_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id google_contributions_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent'" actor_id google_committers_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent'" id google_commits_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id red_hat_contributors_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id red_hat_contributions_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent'" actor_id red_hat_committers_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent'" id red_hat_commits_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id independent_contributors_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id independent_contributions_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent'" actor_id independent_committers_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent'" id independent_commits_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id microsoft_contributors_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" id microsoft_contributions_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent'" actor_id microsoft_committers_cumulative.csv
SKIPFROM=true ./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent'" id microsoft_commits_cumulative.csv
./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id google_contributors.csv
./util_sh/monthly.sh '2014-01-01' "'Google'" "'PushEvent'" actor_id google_committers.csv
./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id red_hat_contributors.csv
./util_sh/monthly.sh '2014-01-01' "'Red Hat'" "'PushEvent'" actor_id red_hat_committers.csv
./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id independent_contributors.csv
./util_sh/monthly.sh '2014-01-01' "'Independent'" "'PushEvent'" actor_id independent_committers.csv
./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent', 'IssuesEvent', 'PullRequestEvent'" actor_id microsoft_contributors.csv
./util_sh/monthly.sh '2014-01-01' "'Microsoft'" "'PushEvent'" actor_id microsoft_committers.csv
