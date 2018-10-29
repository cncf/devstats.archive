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
  count(distinct a.login) as committers,
  count(distinct c.sha) as commits
from
  dates d,
  gha_commits c,
  gha_actors a
where (
      c.committer_id = a.id
      or c.author_id = a.id
      or c.dup_actor_id = a.id
      or c.dup_actor_login = a.login
      or c.dup_author_login = a.login
      or c.dup_committer_login = a.login
    )
    and (lower(a.login) {{exclude_bots}})
    and c.dup_created_at >= d.f
    and c.dup_created_at < d.t
group by
  d.rel,
  d.f,
  d.t
order by
  d.f
;
