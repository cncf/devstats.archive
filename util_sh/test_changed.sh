#!/bin/bash

for f in metrics/shared/companies_tags.sql metrics/shared/reviewers_tags.sql metrics/shared/users_tags.sql 
do
  echo $f
  PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{lim}} 200
done

for f in metrics/shared/company_activity.sql metrics/shared/contributors.sql metrics/shared/countries.sql metrics/shared/countries_cum.sql metrics/shared/num_stats.sql metrics/shared/projects_health.sql metrics/shared/projects_health_all.sql metrics/shared/reviews_per_user.sql metrics/shared/user_activity.sql
do
  echo $f
  PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{n}} 1 {{from}} 2022-04-06 {{to}} 2022-04-07
done

for f in metrics/shared/project_company_stats.sql metrics/shared/project_developer_stats.sql metrics/shared/project_stats.sql 
do
  echo $f
  # PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" qr '1 week,,' > out
  PG_USER=postgres GHA2DB_LOCAL=1 ./runq "$f" {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{project_scale}} 1.0 qr '1 week,,'
done
