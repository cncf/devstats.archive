select
  concat('user;', sub.cuser, '`', sub.repo_group, ';prs'),
  round(sub.prs / {{n}}, 2) as prs
from (
  select dup_user_login as cuser,
    'all' as repo_group,
    count(distinct id) as prs
  from
    gha_pull_requests
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and state = 'open'
    and dup_type = 'PullRequestEvent'
    and (lower(dup_user_login) {{exclude_bots}})
    and dup_user_login in (select users_name from tusers)
  group by
    dup_user_login
  union select pr.dup_user_login as cuser,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct pr.id) as prs
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.state = 'open'
    and pr.dup_type = 'PullRequestEvent'
    and (lower(pr.dup_user_login) {{exclude_bots}})
    and pr.dup_user_login in (select users_name from tusers)
  group by
    pr.dup_user_login,
    coalesce(ecf.repo_group, r.repo_group)
  union select 'All' as cuser,
    'all' as repo_group,
    count(distinct id) as prs
  from
    gha_pull_requests
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and state = 'open'
    and dup_type = 'PullRequestEvent'
    and (lower(dup_user_login) {{exclude_bots}})
  union select 'All' as cuser,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    count(distinct pr.id) as pr
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.state = 'open'
    and pr.dup_type = 'PullRequestEvent'
    and (lower(pr.dup_user_login) {{exclude_bots}})
  group by
    coalesce(ecf.repo_group, r.repo_group)
  order by
    prs desc,
    cuser asc
  ) sub
where
  sub.repo_group is not null
;
