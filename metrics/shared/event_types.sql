select
  'event_types,' || type,
  round(count(id) / {{n}}, 2) as n
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
group by
  type
order by
  n desc,
  type asc
;
