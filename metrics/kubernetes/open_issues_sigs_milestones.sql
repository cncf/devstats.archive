create temp table issues as
select
  i.id as issue_id,
  i.event_id,
  i.milestone_id,
  i.dup_repo_name as repo
from
  gha_issues i
where
  i.is_pull_request = false
  and i.closed_at is null
  and i.created_at < '{{to}}'
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
      and inn.created_at < '{{to}}'
      and inn.is_pull_request = false
      and inn.updated_at < '{{to}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
;

create temp table issues_sigs as
select i.issue_id,
  i.repo,
  lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
from
  issues i,
  gha_issues_labels il
where
  i.event_id = il.event_id
  and i.issue_id = il.issue_id
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
;

create temp table issues_milestones as
select
  i.issue_id,
  i.repo,
  ml.title as milestone
from
  issues i,
  gha_milestones ml
where
  i.milestone_id = ml.id
  and i.event_id = ml.event_id
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
  sub.cnt desc,
  sub.sig_milestone asc
;

drop table issues_milestones;
drop table issues_sigs;
drop table issues;
