select
  'chealthissue,' || r.alias as name,
  count(distinct i.dup_user_login) as value
from
  gha_repos r,
  gha_issues i
where
  r.alias is not null
  and r.id = i.dup_repo_id
  and r.name = i.dup_repo_name
  and not i.is_pull_request
  and i.created_at < '{{to}}'
  and (lower(i.dup_user_login) {{exclude_bots}})
 group by
  r.alias
union select
  'chealthissue,all' as name,
  count(distinct dup_user_login) as value
from
  gha_issues
where
  not is_pull_request
  and created_at < '{{to}}'
  and (lower(dup_user_login) {{exclude_bots}})
union select
  'chealthcommit,' || sub.alias as name,
  count(distinct sub.committer) as value
from (
  select
    r.alias,
    c.dup_actor_login as committer
  from
    gha_repos r,
    gha_commits c
  where
    r.alias is not null
    and r.id = c.dup_repo_id
    and r.name = c.dup_repo_name
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select
    r.alias,
    c.dup_author_login as committer
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_author_login is not null
    and r.alias is not null
    and r.id = c.dup_repo_id
    and r.name = c.dup_repo_name
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select
    r.alias,
    c.dup_committer_login as committer
  from
    gha_repos r,
    gha_commits c
  where
    c.dup_committer_login is not null
    and r.alias is not null
    and r.id = c.dup_repo_id
    and r.name = c.dup_repo_name
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
  ) sub
group by
  sub.alias
union select
  'chealthcommit,all' as name,
  count(distinct sub.committer) as value
from (
  select
    dup_actor_login as committer
  from
    gha_commits
  where
    dup_created_at < '{{to}}'
    and (lower(dup_actor_login) {{exclude_bots}})
  union select
    dup_author_login as committer
  from
    gha_commits
  where
    dup_author_login is not null
    and dup_created_at < '{{to}}'
    and (lower(dup_author_login) {{exclude_bots}})
  union select
    dup_committer_login as committer
  from
    gha_commits
  where
    dup_committer_login is not null
    and dup_created_at < '{{to}}'
    and (lower(dup_committer_login) {{exclude_bots}})
  ) sub
union select
  'chealthcomment,' || r.alias as name,
  count(distinct e.dup_actor_login) as value
from
  gha_repos r,
  gha_events e
where
  r.alias is not null
  and r.id = e.repo_id
  and r.name = e.dup_repo_name
  and e.created_at < '{{to}}'
  and e.type in ('PullRequestEvent', 'PullRequestReviewCommentEvent', 'CommitCommentEvent')
  and (lower(e.dup_actor_login) {{exclude_bots}})
 group by
  r.alias
union select
  'chealthcomment,all' as name,
  count(distinct dup_actor_login) as value
from
  gha_events
where
  created_at < '{{to}}'
  and type in ('PullRequestEvent', 'PullRequestReviewCommentEvent', 'CommitCommentEvent')
  and (lower(dup_actor_login) {{exclude_bots}})
;
