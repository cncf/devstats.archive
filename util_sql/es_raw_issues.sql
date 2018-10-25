select
  i.id,
  i.event_id,
  i.dup_created_at,
  i.created_at
from
  gha_issues i
where
  i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
;

