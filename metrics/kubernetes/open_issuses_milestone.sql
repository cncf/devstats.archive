create temp table prs as
select sub.issue_id
from (
  select
    ipr.issue_id as issue_id,
    min(pr.created_at) as opened_at,
    max(pr.closed_at) as closed_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr
  where
    ipr.pull_request_id = pr.id
    and pr.created_at < '{{to}}'
    and pr.dup_repo_name = 'kubernetes/kubernetes'
  group by
    ipr.issue_id
  ) sub
where
  sub.closed_at is null or sub.closed_at >= '{{to}}'
;

create temp table sigs as
select pr.issue_id,
  max(il.event_id) as event_id
from
  prs pr,
  gha_issues_labels il
where
  il.issue_id = pr.issue_id
  and il.dup_created_at < '{{to}}'
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
group by
  pr.issue_id
;

create temp table prs_sigs as
select sub.issue_id,
  sub.sig_label
from (
  select
    sig.issue_id,
    sig.event_id,
    lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig_label
  from
    sigs sig,
    gha_issues_labels il
  where
    sig.event_id = il.event_id
    and sig.issue_id = il.issue_id
  ) sub
where
  sub.sig_label is not null
;


drop table prs_sigs;
drop table sigs;
drop table prs;
