create temp table issues as
select i.id as issue_id,
  i.event_id as last_event_id,
  i.updated_at as last_updated
from
  gha_issues i
where
  i.is_pull_request = false
  and i.id > 0
  and i.event_id > 0
  and i.closed_at is null
  and i.created_at < '{{date}}'
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
      and inn.id > 0
      and inn.event_id > 0
      and inn.created_at < '{{date}}'
      and inn.is_pull_request = false
      and inn.updated_at < '{{date}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
order by
  i.updated_at desc
;

select * from issues;

drop table issues;
