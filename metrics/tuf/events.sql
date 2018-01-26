select
  count(id) as count
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
;
