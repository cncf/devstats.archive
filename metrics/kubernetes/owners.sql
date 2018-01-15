select
  coalesce(max(size), 0) as size
from
  gha_events_commits_files
where
  path = 'kubernetes/kubernetes/OWNERS'
  and dt < '{{to}}'
;
