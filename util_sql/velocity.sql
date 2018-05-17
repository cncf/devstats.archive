with days as (
  select
    date_part('day', '{{date_to}}'::timestamp - '{{date_from}}'::timestamp) as days
)
select
  e.dup_repo_name as repo,
  count(e.id) / d.days as metric_per_day
from
  gha_events e,
  days d
where
  e.type in ({{types}})
  and (lower(e.dup_actor_login) {{exclude_bots}})
  and e.created_at >= '{{date_from}}'
  and e.created_at < '{{date_to}}'
group by
  e.dup_repo_name,
  d.days
union select 'All' as repo,
  count(e.id) / d.days as metric_per_day
from
  gha_events e,
  days d
where
  e.type in ({{types}})
  and (lower(e.dup_actor_login) {{exclude_bots}})
  and e.created_at >= '{{date_from}}'
  and e.created_at < '{{date_to}}'
group by
  d.days
order by
  metric_per_day desc,
  repo asc
;
