with dtfrom as (
  select '{{to}}'::timestamp - '1 year'::interval as dtfrom
), issues as (
  select sub.issue_id,
    sub.event_id,
    sub.repo_name,
    sub.repo_id
  from (
    select distinct
      id as issue_id,
      dup_repo_name as repo_name,
      dup_repo_id as repo_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at
    from
      gha_issues,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
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
    i.repo_name,
    i.repo_id
  from (
    select distinct id as pr_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
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
), labels as (
  select il.issue_id,
    pr.repo_name,
    pr.repo_id,
    il.dup_label_name as label,
    il.event_id
  from
    prs pr,
    gha_issues_labels il
  where
    il.issue_id = pr.issue_id
    and il.event_id = pr.event_id
    and il.dup_label_name in (
      'cla: no',
      'cncf-cla: no',
      'do-not-merge',
      'do-not-merge/blocked-paths',
      'do-not-merge/cherry-pick-not-approved',
      'do-not-merge/hold',
      'do-not-merge/release-note-label-needed',
      'do-not-merge/work-in-progress',
      'priority/critical-urgent',
      'needs-ok-to-test',
      'needs-rebase',
      'needs-priority',
      'release-note-label-needed'
    )
)
select
  sub.name,
  count(distinct sub.issue_id) as label_count
from (
  select 'prlbl,' || r.repo_name || ': All labels combined' as name,
    r.issue_id
  from
    labels r
  where
    r.repo_name in (select repo_name from trepos)
  union select 'prlbl,' || r.repo_name || ': ' || r.label as name,
    r.issue_id
  from
    labels r
  where
    r.repo_name in (select repo_name from trepos)
  union select 'prlbl,All repos combined: All labels combined' as name,
    r.issue_id
  from
    labels r
  union select 'prlbl,All repos combined: ' || r.label as name,
    r.issue_id
  from
    labels r
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  label_count desc,
  name asc
;
