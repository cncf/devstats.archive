select
  sub.repo_group,
  sub.author,
  count(distinct sub.id) as prs
from (
  select 'hpr_auth,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.dup_user_login as author,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    {{period:pr.created_at}}
    and pr.dup_repo_id = r.id
    and pr.dup_repo_name = r.name
    -- and pr.dup_type = 'PullRequestEvent'
    -- and pr.state = 'open'
    and (lower(pr.dup_user_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.author
having
  count(distinct sub.id) >= 1
union select 'hpr_auth,All' as repo_group,
  dup_user_login as author,
  count(distinct id) as prs
from
  gha_pull_requests
where
  {{period:created_at}}
  -- and dup_type = 'PullRequestEvent'
  -- and state = 'open'
  and (lower(dup_user_login) {{exclude_bots}})
group by
  dup_user_login
having
  count(distinct id) >= 1
order by
  prs desc,
  repo_group asc,
  author asc
;
