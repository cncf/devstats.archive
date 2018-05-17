with start_date as (
  select '{{start_date}}' as string,
    '{{start_date}}'::date as date,
    '{{start_date}}'::timestamp as timestamp,
    date_trunc('month', '{{start_date}}'::date) as month_date
), dates as (
  select (select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)) as f,
    (select month_date from start_date) + (interval '1' month * (1 + generate_series(0,month_count::int))) as t,
    to_char((select month_date from start_date) + (interval '1' month * generate_series(0,month_count::int)), 'MM/YYYY') as rel
  from (
    select (date_part('year', now()) - date_part('year', (select date from start_date))) * 12 + (date_part('month', now()) - date_part('month', (select date from start_date))) as month_count
  ) sub
)
select
  d.rel,
  d.f,
  d.t,
  count(distinct e.actor_id) as contributors
from
  dates d,
  gha_events e
where
  e.created_at >= d.f
  and e.created_at < d.t
  and e.type in ('PushEvent', 'IssuesEvent', 'PullRequestEvent')
  and (lower(e.dup_actor_login) {{exclude_bots}})
group by
  d.rel,
  d.f,
  d.t
order by
  d.f
;
