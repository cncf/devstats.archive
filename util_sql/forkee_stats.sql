select
  forks = 0 as no_forks,
  watchers = 0 as no_watchers,
  open_issues = 0 as no_open_issues,
  count(*) as cnt
from
  gha_forkees
group by
  no_forks,
  no_watchers,
  no_open_issues
order by
  cnt desc;
