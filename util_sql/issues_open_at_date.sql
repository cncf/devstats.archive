select
  sub.issue_id,
  sub.last_event_id,
  sub.last_updated
from (
  select distinct
    id as issue_id,
    last_value(closed_at) over issues_ordered_by_update as closed_at,
    last_value(event_id) over issues_ordered_by_update as last_event_id,
    last_value(updated_at) over issues_ordered_by_update as last_updated
  from
    gha_issues
  where
    created_at < '{{date}}'
    and updated_at < '{{date}}'
    and is_pull_request = false
  window
    issues_ordered_by_update as (
      partition by id
      order by
        updated_at asc,
        event_id asc
      range between current row
      and unbounded following
    )
  ) sub
where
  sub.closed_at is null
order by
  sub.last_updated desc
;
