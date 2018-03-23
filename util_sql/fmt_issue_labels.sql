select
  coalesce(string_agg(sub.label_id::text, ','), '') as labels,
  sub.event_id
from (
  select label_id,
    event_id
  from
    gha_issues_labels
  where
    event_id in (
      select event_id
    from
      gha_issues_labels
    where
      issue_id = %s
    order by
      dup_created_at desc
    limit 1
  )
  order by
    1 asc
) sub
group by
  sub.event_id
;
