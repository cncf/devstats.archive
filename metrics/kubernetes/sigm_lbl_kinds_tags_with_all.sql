select
  sub.kind
from (
  select sel.kind as kind,
    count(distinct issue_id) as cnt
  from (
    select distinct issue_id,
      lower(substring(dup_label_name from '(?i)kind/(.*)')) as kind
    from
      gha_issues_labels
    ) sel
  where
    sel.kind is not null
  group by
    kind
  order by
    cnt desc,
    kind asc
  limit {{lim}}
) sub
union select 'All'
;
