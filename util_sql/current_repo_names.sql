select
  distinct last_value(dup_repo_name) over events_by_date as repo_name
from
  gha_events
window
  events_by_date as (
    partition by
      repo_id
    order by
      created_at asc
    range between current row
    and unbounded following
  )
order by
  repo_name
;
