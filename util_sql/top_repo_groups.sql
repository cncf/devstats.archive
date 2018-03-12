select
  string_agg(sel.repo_group, ',')
from (
  select r.repo_group,
    count(distinct e.id) as cnt
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
    and r.repo_group is not null
  group by
    r.repo_group
  union select 'All' as repo_group,
    count(distinct id) as cnt
  from
    gha_events
  order by
    cnt desc,
    repo_group asc
  limit {{lim}}
  ) sel
;
