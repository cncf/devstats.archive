select
  concat('user;', sub.cuser, '`', sub.repo_group, ';issues'),
  round(sub.issues / {{n}}, 2) as issues
from (
  select dup_user_login as cuser,
    'all' as repo_group,
    count(distinct id) as issues
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and state = 'open'
    and is_pull_request = false
    and dup_type = 'IssuesEvent'
    and (lower(dup_user_login) {{exclude_bots}})
    and dup_user_login in (select users_name from tusers)
  group by
    dup_user_login
  union select i.dup_user_login as cuser,
    r.repo_group as repo_group,
    count(distinct i.id) as issues
  from
    gha_repos r,
    gha_issues i
  where
    r.id = i.dup_repo_id
    and r.name = i.dup_repo_name
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.state = 'open'
    and i.is_pull_request = false
    and i.dup_type = 'IssuesEvent'
    and (lower(i.dup_user_login) {{exclude_bots}})
    and i.dup_user_login in (select users_name from tusers)
  group by
    i.dup_user_login,
    r.repo_group
  union select 'All' as cuser,
    'all' as repo_group,
    count(distinct id) as issues
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and state = 'open'
    and is_pull_request = false
    and dup_type = 'IssuesEvent'
    and (lower(dup_user_login) {{exclude_bots}})
  union select 'All' as cuser,
    r.repo_group as repo_group,
    count(distinct i.id) as issues
  from
    gha_repos r,
    gha_issues i
  where
    r.id = i.dup_repo_id
    and r.name = i.dup_repo_name
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.state = 'open'
    and i.is_pull_request = false
    and i.dup_type = 'IssuesEvent'
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    r.repo_group
  order by
    issues desc,
    cuser asc
  ) sub
where
  sub.repo_group is not null
;
