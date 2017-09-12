select
  sel.sig as sig,
  count(distinct issue_id) as cnt
from (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
  ) sel
where
  sel.sig is not null
group by
  sig
order by
  cnt desc
