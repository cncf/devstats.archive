select
  distinct last_value(dup_repo_name) over by_date as repo_name
from (
  select
    repo_id,
    dup_repo_name,
    max(created_at) as max_date
  from
    gha_events
  where
    dup_repo_name like '%_/_%'
  group by
    repo_id,
    dup_repo_name
) sub
window
  by_date as (
    partition by
      repo_id
    order by
      max_date asc
    range
      between unbounded preceding
      and unbounded following
  )
order by
  repo_name
;
