select
  lower(l.name) as label,
  count(distinct issue_id) as cnt
from
  gha_labels l,
  gha_issues_labels il
where
  l.id = il.label_id
  and substring(l.name from '(?i){{re}}') is not null
group by
  l.name
order by
  cnt desc,
  label asc;
