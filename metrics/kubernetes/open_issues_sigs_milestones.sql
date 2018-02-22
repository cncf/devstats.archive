create temp table issues as
select sub.issue_id
from (
  select
    i.id as issue_id,
    min(i.created_at) as opened_at,
    max(i.closed_at) as closed_at
  from
    gha_issues i
  where
    i.is_pull_request = false
    and i.created_at < '{{to}}'
    and i.dup_repo_name = 'kubernetes/kubernetes'
  group by
    i.id
  ) sub
where
  sub.closed_at is null or sub.closed_at >= '{{to}}'
;

create temp table sigs as
select i.issue_id,
  max(il.event_id) as event_id
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.issue_id
  and il.dup_created_at < '{{to}}'
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
group by
  i.issue_id
;

create temp table issues_sigs as
select sub.issue_id,
  sub.sig_label as sig
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

create temp table milestones as
select ci.issue_id,
  max(i.event_id) as event_id
from
  issues ci,
  gha_issues i
where
  i.id = ci.issue_id
  and i.dup_created_at < '{{to}}'
  and i.milestone_id is not null
group by
  ci.issue_id
;

create temp table issues_milestones as
select
  mi.issue_id,
  ml.title as milestone
from
  milestones mi,
  gha_issues i,
  gha_milestones ml
where
  mi.issue_id = i.id
  and mi.event_id = i.event_id
  and i.milestone_id = ml.id
  and mi.event_id = ml.event_id
;

select 
  sub.sig_milestone,
  sub.cnt
from (
  select concat('open_issues_sigs_milestones,', s.sig, '-', m.milestone) as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_milestones m,
    issues_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('open_issues_sigs_milestones,', 'All-', m.milestone) as sig_milestone,
    count(m.issue_id) as cnt
  from
    issues_milestones m
  group by
    m.milestone
  union select concat('open_issues_sigs_milestones,', s.sig, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_sigs s
  group by
    s.sig
  union select 'open_issues_sigs_milestones,All-All' as sig_milestone,
    count(i.issue_id) as cnt
  from
    issues i
  ) sub
order by
  sub.cnt desc
;

drop table issues_milestones;
drop table milestones;
drop table issues_sigs;
drop table sigs;
drop table issues;
