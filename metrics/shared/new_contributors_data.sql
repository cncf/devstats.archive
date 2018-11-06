with prev as (
  select distinct user_id
  from
    gha_pull_requests
  where
    created_at < '{{from}}'
), contributors as (
  select distinct pr.user_id,
    min(pr.created_at) as created_at
  from
    gha_pull_requests pr
  left join
    prev pc
  on
    pc.user_id = pr.user_id
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.user_id not in (select user_id from prev)
  group by
    pr.user_id
)
select
  'new_contributors_data,All' as metric,
  c.created_at,
  0.0 as value,
  case a.name is null when true then a.login else case a.name when '' then a.login else a.name || ' (' || a.login || ')' end end as contributor
from
  contributors c,
  gha_actors a
where
  c.user_id = a.id
order by
  c.created_at asc,
  contributor asc
;
