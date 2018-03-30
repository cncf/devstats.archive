with issues as (
  select sub.issue_id,
    sub.event_id,
    sub.repo_name
  from (
    select distinct
      id as issue_id,
      dup_repo_name as repo_name,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at
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
    i.repo_name
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
), labels as (
  select il.issue_id,
    pr.repo_name,
    il.dup_label_name as label,
    il.event_id
  from
    prs pr,
    gha_issues_labels il
  where
    il.issue_id = pr.issue_id
    and il.event_id = pr.event_id
    and il.dup_label_name in (
      'needs-rebase',
      'needs-ok-to-test',
      'do-not-merge',
      'cla: no',
      'release-note-label-needed'
    )
)
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
union select 'prs_labelled,All repos combined: All labels combined' as name,
  r.issue_id
from
  labels r
union select 'prs_labelled,All repos combined: ' || r.label as name,
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
