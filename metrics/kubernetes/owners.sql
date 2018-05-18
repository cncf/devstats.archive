select
  sum(sub.size)
from (
  select path,
    max(size) as size
  from
    gha_events_commits_files
  where
    path like 'kubernetes/kubernetes/%/OWNERS'
    and dt < '{{to}}'
    and size > 0
  group by
    path
) sub
;
