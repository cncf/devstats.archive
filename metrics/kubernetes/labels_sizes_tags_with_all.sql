select
  sub.size
from (
  select sel.size as size,
    count(distinct issue_id) as cnt
  from (
    select distinct issue_id,
      substring(dup_label_name from '(?i)size/(.*)') as size
    from
      gha_issues_labels
    ) sel
  where
    sel.size is not null
  group by
    size
  order by
    cnt desc,
    size asc
  limit {{lim}}
) sub
union select 'All'
;
