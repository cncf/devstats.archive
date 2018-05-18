select
  concat('iclosed_lsk,', sel1.sig, '-', sel2.kind) as sig_kind,
  round(count(distinct sel1.id) / {{n}}, 2) as cnt
from (
  select distinct i.id,
    lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels il,
    gha_issues i
  where
    i.id = il.issue_id
    and i.closed_at >= '{{from}}'
    and i.closed_at < '{{to}}'
  union select id,
    'All' as sig
  from
    gha_issues
  where
    closed_at >= '{{from}}'
    and closed_at < '{{to}}'
  ) sel1, (
  select distinct i.id,
    lower(substring(il.dup_label_name from '(?i)kind/(.*)')) as kind
  from
    gha_issues_labels il,
    gha_issues i
  where
    i.id = il.issue_id
    and i.closed_at >= '{{from}}'
    and i.closed_at < '{{to}}'
  union select id,
    'All' as kind
  from
    gha_issues
  where
    closed_at >= '{{from}}'
    and closed_at < '{{to}}'
  ) sel2
where
  sel1.id = sel2.id
  and sel1.sig is not null
  and sel2.kind is not null
group by
  sig_kind
order by
  cnt desc,
  sig_kind asc;
