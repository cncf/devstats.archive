with prs as (
  select ipr.issue_id,
    pr.created_at,
    pr.merged_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr
  where
    pr.id = ipr.pull_request_id
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id
      from
        gha_pull_requests i
      where
        i.id = pr.id
        and i.created_at >= '{{from}}'
        and i.created_at < '{{to}}'
      order by
        i.updated_at desc
      limit 1
    )
), prs_groups as (
  select r.repo_group,
    ipr.issue_id,
    pr.created_at,
    pr.merged_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr,
    gha_repos r
  where
    r.id = ipr.repo_id
    and r.name = ipr.repo_name
    and r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and r.repo_group is not null
    and pr.id = ipr.pull_request_id
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id
      from
        gha_pull_requests i
      where
        i.id = pr.id
        and i.created_at >= '{{from}}'
        and i.created_at < '{{to}}'
      order by
        i.updated_at desc
      limit 1
    )
)
select * from prs_groups;
