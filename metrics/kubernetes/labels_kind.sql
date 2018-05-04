select
  'sigm_lk,' || sel.kind as kind,
  round(count(distinct issue_id) / {{n}}, 2) as cnt
from (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)kind/(.*)')) as kind
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
  ) sel
where
  sel.kind is not null
group by
  kind
order by
  cnt desc,
  kind asc;
