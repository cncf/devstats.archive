select
  sub.prio
from (
  select sel.prio as prio,
    count(distinct issue_id) as cnt
  from (
    select distinct issue_id,
      substring(dup_label_name from '(?i)priority/(.*)') as prio
    from
      gha_issues_labels
    ) sel
  where
    sel.prio is not null
  group by
    prio
  order by
    cnt desc,
    prio asc
  limit {{lim}}
) sub
union select 'All'
;
