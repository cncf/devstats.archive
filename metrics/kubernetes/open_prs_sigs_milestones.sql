with issues as (
  select sub.issue_id,
    sub.event_id,
    sub.milestone_id,
    sub.repo
  from (
    select distinct
      id as issue_id,
      dup_repo_name as repo,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at,
      last_value(milestone_id) over issues_ordered_by_update as milestone_id
    from
      gha_issues
    where
      created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = true
    window
      issues_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) sub
  where
    sub.closed_at is null
), prs as (
  select i.issue_id,
    i.event_id,
    i.milestone_id,
    i.repo
  from (
    select distinct id as pr_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests
    where
      created_at < '{{to}}'
      and updated_at < '{{to}}'
      and event_id > 0
    window
      prs_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) pr,
    issues i,
    gha_issues_pull_requests ipr
  where
    ipr.issue_id = i.issue_id
    and ipr.pull_request_id = pr.pr_id
    and pr.closed_at is null
    and pr.merged_at is null
), prs_sigs as (
  select pr.issue_id,
    pr.repo,
    lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
  from
    prs pr,
    gha_issues_labels il
  where
    pr.event_id = il.event_id
    and pr.issue_id = il.issue_id
    and lower(substring(il.dup_label_name from '(?i)sig/(.*)')) is not null
), prs_milestones as (
  select pr.issue_id,
    pr.repo,
    ml.title as milestone
  from
    prs pr,
    gha_milestones ml
  where
    pr.milestone_id = ml.id
    and pr.event_id = ml.event_id
)
select 
  sub.sig_milestone,
  sub.cnt
from (
  select concat('prsigml,', s.sig, '-', m.milestone, '-', s.repo) as sig_milestone,
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
  union select concat('prsigml,', 'All-', m.milestone, '-', m.repo) as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone,
    m.repo
  union select concat('prsigml,', s.sig, '-All-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig,
    s.repo
  union select concat('prsigml,All-All-', pr.repo) as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  group by
    pr.repo
  union select concat('prsigml,', s.sig, '-', m.milestone, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_milestones m,
    prs_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('prsigml,', 'All-', m.milestone, '-All') as sig_milestone,
    count(m.issue_id) as cnt
  from
    prs_milestones m
  group by
    m.milestone
  union select concat('prsigml,', s.sig, '-All-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    prs_sigs s
  group by
    s.sig
  union select 'prsigml,All-All-All' as sig_milestone,
    count(pr.issue_id) as cnt
  from
    prs pr
  ) sub
order by
  sub.cnt desc,
  sub.sig_milestone asc
;
