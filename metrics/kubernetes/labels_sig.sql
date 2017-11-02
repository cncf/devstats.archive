select
  'sig_mentions_labels_sig,' || sel.sig as sig,
  round(count(distinct issue_id) / {{n}}, 2) as cnt
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
  cnt desc,
  sig asc;
