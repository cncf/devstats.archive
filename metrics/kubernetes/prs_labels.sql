create temp table issues as
select sub.id,
  sub.repo_name,
  sub.created,
  sub.closed
from (
  select i.id,
    i.dup_repo_name as repo_name,
    min(pr.created_at) as created,
    max(pr.closed_at) as closed
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr,
    gha_issues i
  where
    ipr.issue_id = i.id
    and ipr.pull_request_id = pr.id
    and i.number = pr.number
    and i.dup_repo_id = pr.dup_repo_id
    and i.is_pull_request = true
    and pr.created_at < '{{to}}'
  group by
    i.id,
    i.dup_repo_name
  ) sub
where
  sub.closed is null
  or sub.closed >= '{{to}}'
;

create temp table labels as
select il.issue_id,
  i.repo_name,
  il.dup_label_name as label,
  max(il.dup_created_at) as label_dt,
  min(il.event_id) as event_id
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.id
  and il.dup_label_name in (
    'needs-rebase',
    'needs-ok-to-test',
    'do-not-merge',
    'cla: no',
    'release-note-label-needed'
  )
  and il.dup_created_at >= i.created
  and il.dup_created_at < '{{to}}'
  and (
    i.closed is null
    or (
      il.dup_created_at <= i.closed
      and i.closed >= '{{to}}'
    )
  )
group by
  il.issue_id,
  i.repo_name,
  il.dup_label_name
;

create temp table removed_labels as
select il.issue_id,
  r.repo_name,
  r.label,
  min(il.dup_created_at) as removed_dt
from
  gha_issues_labels il,
  labels r
where
  r.issue_id = il.issue_id
  and il.dup_created_at > r.label_dt
  and il.dup_created_at < '{{to}}'
group by
  il.issue_id,
  r.repo_name,
  r.label
;

select
  sub.name,
  count(distinct sub.issue_id) as label_count
from (
  select 'prs_labelled,' || coalesce(ecf.repo_group, re.repo_group) || ': All labels combined' as name,
    r.issue_id
  from
    labels r
  join
    gha_repos re
  on
    r.repo_name = re.name
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = r.event_id
  left join
    removed_labels rr
  on
    r.issue_id = rr.issue_id
    and r.label = rr.label
  where
    rr.issue_id is null
  union select 'prs_labelled,' || coalesce(ecf.repo_group, re.repo_group) || ': ' || r.label as name,
    r.issue_id
  from
    labels r
  join
    gha_repos re
  on
    r.repo_name = re.name
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = r.event_id
  left join
    removed_labels rr
  on
    r.issue_id = rr.issue_id
    and r.label = rr.label
  where
    rr.issue_id is null
union select 'prs_labelled,All repos combined: All labels combined' as name,
  r.issue_id
from
  labels r
left join
  removed_labels rr
on
  r.issue_id = rr.issue_id
  and r.label = rr.label
where
  rr.issue_id is null
union select 'prs_labelled,All repos combined: ' || r.label as name,
  r.issue_id
from
  labels r
left join
  removed_labels rr
on
  r.issue_id = rr.issue_id
  and r.label = rr.label
where
  rr.issue_id is null
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  label_count desc,
  name asc
;

drop table removed_labels;
drop table labels;
drop table issues;
