create temp table prs as
select sub.issue_id,
  sub.repo
from (
  select
    ipr.issue_id as issue_id,
    pr.dup_repo_name as repo,
    min(pr.created_at) as opened_at,
    max(pr.closed_at) as closed_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr
  where
    ipr.pull_request_id = pr.id
    and pr.created_at < '{{to}}'
  group by
    ipr.issue_id,
    pr.dup_repo_name
  ) sub
where
  sub.closed_at is null or sub.closed_at >= '{{to}}'
;

create temp table sigs as
select pr.issue_id,
  pr.repo,
  max(il.event_id) as event_id
from
  prs pr,
  gha_issues_labels il
where
  il.issue_id = pr.issue_id
  and il.dup_created_at < '{{to}}'
  and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
group by
  pr.issue_id,
  pr.repo
;

create temp table prs_sigs as
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

create temp table milestones as
select pr.issue_id,
  pr.repo,
  max(i.event_id) as event_id
from
  prs pr,
  gha_issues i
where
  i.id = pr.issue_id
  and i.dup_created_at < '{{to}}'
  and i.milestone_id is not null
group by
  pr.issue_id,
  pr.repo
;

create temp table prs_milestones as
select
  pr.issue_id,
  pr.repo,
  ml.title as milestone
from
  milestones pr,
  gha_issues i,
  gha_milestones ml
where
  pr.issue_id = i.id
  and pr.event_id = i.event_id
  and i.milestone_id = ml.id
  and pr.event_id = ml.event_id
;

select 
  sub.sig_milestone,
  sub.cnt
from (
  select concat('open_prs_sigs_milestones,', s.sig, '-', m.milestone, '-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_milestones m,
    prs_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone,
    s.repo
  union select concat('open_prs_sigs_milestones,', 'All-', m.milestone, '-', m.milestone) as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone,
    m.repo
  union select concat('open_prs_sigs_milestones,', s.sig, '-All-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig,
    s.repo
  union select concat('open_prs_sigs_milestones,All-All-', pr.repo) as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  group by
    pr.repo
  union select concat('open_prs_sigs_milestones,', s.sig, '-', m.milestone, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_milestones m,
    prs_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('open_prs_sigs_milestones,', 'All-', m.milestone, '-All') as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone
  union select concat('open_prs_sigs_milestones,', s.sig, '-All-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig
  union select 'open_prs_sigs_milestones,All-All-All' as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  ) sub
order by
  sub.cnt desc
;

drop table prs_milestones;
drop table milestones;
drop table prs_sigs;
drop table sigs;
drop table prs;
