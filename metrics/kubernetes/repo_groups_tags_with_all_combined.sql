select
  'All repos combined' as repo_group
union select distinct repo_group
from
  gha_repos
where
  repo_group is not null
order by
  repo_group asc
;
