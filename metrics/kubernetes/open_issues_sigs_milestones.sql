create temp table issues as
select sub.issue_id,
  sub.repo
from (
  select
    i.id as issue_id,
    i.dup_repo_name as repo,
    min(i.created_at) as opened_at,
    max(i.closed_at) as closed_at
  from
    gha_issues i
  where
    i.is_pull_request = false
    and i.created_at < '{{to}}'
  group by
    i.id,
    i.dup_repo_name
  ) sub
where
  sub.closed_at is null or sub.closed_at >= '{{to}}'
;

create temp table final_sigs as
select i.issue_id,
  i.repo,
  max(il.event_id) as event_id,
  max(il.dup_created_at) as sig_dt
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.issue_id
  and il.dup_created_at < '{{to}}'
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
group by
  i.issue_id,
  i.repo
;

create temp table removed_sigs as
select distinct il.issue_id,
  il.dup_repo_name as repo
from
  gha_issues_labels il,
  final_sigs s
where
  s.issue_id = il.issue_id
  and il.dup_created_at > s.sig_dt
  and il.dup_created_at < '{{to}}'
;

create temp table sigs as
select s.issue_id,
  s.repo,
  s.event_id
from
  final_sigs s
left join
  removed_sigs rs
on
  s.issue_id = rs.issue_id
where
  rs.issue_id is null
;

create temp table issues_sigs as
select sub.issue_id,
  sub.repo,
  sub.sig_label as sig
from (
  select
    sig.issue_id,
    sig.repo,
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

create temp table final_milestones as
select ci.issue_id,
  ci.repo,
  max(i.event_id) as event_id,
  max(i.dup_created_at) as milestone_dt
from
  issues ci,
  gha_issues i
where
  i.id = ci.issue_id
  and i.dup_created_at < '{{to}}'
  and i.milestone_id is not null
group by
  ci.issue_id,
  ci.repo
;

create temp table removed_milestones as
select distinct sub.issue_id,
  sub.repo
from (
  select distinct i.id as issue_id,
    i.dup_repo_name as repo
  from
    gha_issues i,
    final_milestones m
  where
    i.milestone_id is null
    and m.issue_id = i.id
    and i.dup_created_at > m.milestone_dt
    and i.dup_created_at < '{{to}}'
  union distinct select il.issue_id,
    il.dup_repo_name as repo
  from
    gha_issues_labels il,
    final_milestones m
  where
    m.issue_id = il.issue_id
    and il.dup_created_at >= m.milestone_dt
    and il.dup_created_at < '{{to}}'
    and lower(il.dup_label_name) = 'milestone/removed'
  ) sub
group by
  sub.issue_id,
  sub.repo
;

create temp table milestones as
select m.issue_id,
  m.repo,
  (select coalesce(min(pl.event_id), m.event_id) from gha_payloads pl where pl.issue_id = m.issue_id and pl.event_id > m.event_id) as event_id
from
  final_milestones m
left join
  removed_milestones rm
on
  m.issue_id = rm.issue_id
where
  rm.issue_id is null
;

create temp table issues_milestones as
select
  mi.issue_id,
  mi.repo,
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
  select concat('open_issues_sigs_milestones,', s.sig, '-', m.milestone, '-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_milestones m,
    issues_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone,
    s.repo
  union select concat('open_issues_sigs_milestones,', 'All-', m.milestone, '-', m.repo) as sig_milestone,
    count(m.issue_id) as cnt
  from
    issues_milestones m
  group by
    m.milestone,
    m.repo
  union select concat('open_issues_sigs_milestones,', s.sig, '-All-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_sigs s
  group by
    s.sig,
    s.repo
  union select concat('open_issues_sigs_milestones,All-All-', i.repo) as sig_milestone,
    count(i.issue_id) as cnt
  from
    issues i
  group by
    i.repo
  union select concat('open_issues_sigs_milestones,', s.sig, '-', m.milestone, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_milestones m,
    issues_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('open_issues_sigs_milestones,', 'All-', m.milestone, '-All') as sig_milestone,
    count(m.issue_id) as cnt
  from
    issues_milestones m
  group by
    m.milestone
  union select concat('open_issues_sigs_milestones,', s.sig, '-All-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_sigs s
  group by
    s.sig
  union select 'open_issues_sigs_milestones,All-All-All' as sig_milestone,
    count(i.issue_id) as cnt
  from
    issues i
  ) sub
order by
  sub.cnt desc
;

drop table issues_milestones;
drop table milestones;
drop table removed_milestones;
drop table final_milestones;
drop table issues_sigs;
drop table sigs;
drop table removed_sigs;
drop table final_sigs;
drop table issues;
