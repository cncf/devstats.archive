#!/bin/bash
#for f in metrics/kubernetes/hist_reviewers.sql metrics/kubernetes/hist_reviewers_repos.sql metrics/kubernetes/project_developer_stats.sql metrics/kubernetes/project_developer_stats_repos.sql metrics/kubernetes/project_stats.sql metrics/kubernetes/project_stats_repos.sql
for f in metrics/kubernetes/project_stats.sql metrics/kubernetes/project_stats_repos.sql
do
  echo $f
  # PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" qr '1 week,,' > out
  PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" qr '1 week,,'
done
for f in metrics/kubernetes/company_activity.sql metrics/kubernetes/company_activity_repos.sql metrics/kubernetes/contributors.sql metrics/kubernetes/contributors_repos.sql metrics/kubernetes/countries.sql metrics/kubernetes/countries_cum.sql metrics/kubernetes/github_stats_by_repos_comps.sql metrics/kubernetes/num_stats.sql metrics/kubernetes/num_stats_repos.sql metrics/kubernetes/reviewers.sql metrics/kubernetes/reviewers_repos.sql metrics/kubernetes/reviews_per_user.sql metrics/kubernetes/user_activity.sql metrics/kyverno/community_health.sql
do
  echo $f
  PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{n}} 1 {{from}} 2022-04-06 {{to}} 2022-04-07
done
