select
  txt.event_id,
  txt.body,
  txt.created_at
from
  gha_texts txt
where
  txt.created_at >= '{{from}}'
  and txt.created_at < '{{to}}'
;

