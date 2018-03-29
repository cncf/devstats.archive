with issues as (
  select sub.issue_id,
    sub.event_id,
    sub.updated_at
  from (
    select distinct
      id as issue_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at,
      last_value(updated_at) over issues_ordered_by_update as updated_at
    from
      gha_issues
    where
      created_at < '{{date}}'
      and updated_at < '{{date}}'
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
    i.event_id as last_issue_event_id,
    i.updated_at as issue_last_updated,
    pr.pr_id,
    pr.event_id as last_pr_event_id,
    pr.updated_at as pr_last_updated
  from (
    select distinct
      id as pr_id,
      last_value(event_id) over prs_ordered_by_update as event_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at,
      last_value(updated_at) over prs_ordered_by_update as updated_at
    from
      gha_pull_requests
    where
      created_at < '{{date}}'
      and updated_at < '{{date}}'
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
)
select * from prs;
