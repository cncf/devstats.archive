select
  concat('sigm_lsk,', sel1.sig, '-', sel2.kind) as sig_kind,
  round(count(distinct sel1.issue_id) / {{n}}, 2) as cnt
from (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
  union select id as issue_id,
    'All' as sig
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
  ) sel1, (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)kind/(.*)')) as kind
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
  union select id as issue_id,
    'All' as kind
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
  ) sel2
where
  sel1.issue_id = sel2.issue_id
  and sel1.sig is not null
  and sel2.kind is not null
group by
  sig_kind
order by
  cnt desc,
  sig_kind asc;
