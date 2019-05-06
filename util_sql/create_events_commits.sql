insert into gha_events_commits_files(
  sha,
  event_id,
  path,
  dt,
  size,
  dup_repo_id,
  dup_repo_name,
  dup_type,
  dup_created_at
)
select
  distinct sub.sha,
  sub.event_id,
  sub.path,
  sub.dt,
  sub.size,
  sub.dup_repo_id,
  sub.dup_repo_name,
  sub.dup_type,
  sub.dup_created_at
from (
  select cf.sha,
    c.event_id,
    c.dup_repo_name || '/' || cf.path as path,
    cf.dt,
    cf.size,
    c.dup_repo_id,
    c.dup_repo_name,
    c.dup_type,
    c.dup_created_at
  from
    gha_comments c,
    gha_commits_files cf
  where
    c.commit_id = cf.sha
    -- or c.original_commit_id = cf.sha
  union select cf.sha,
    c.event_id,
    c.dup_repo_name || '/' || cf.path as path,
    cf.dt,
    cf.size,
    c.dup_repo_id,
    c.dup_repo_name,
    c.dup_type,
    c.dup_created_at
  from
    gha_commits c,
    gha_commits_files cf
  where
    c.sha = cf.sha
  union select cf.sha,
    p.event_id,
    p.dup_repo_name || '/' || cf.path as path,
    cf.dt,
    cf.size,
    p.dup_repo_id,
    p.dup_repo_name,
    p.dup_type,
    p.dup_created_at
  from
    gha_pages p,
    gha_commits_files cf
  where
    p.sha = cf.sha
  union select cf.sha,
    pl.event_id,
    pl.dup_repo_name || '/' || cf.path as path,
    cf.dt,
    cf.size,
    pl.dup_repo_id,
    pl.dup_repo_name,
    pl.dup_type,
    pl.dup_created_at
  from
    gha_payloads pl,
    gha_commits_files cf
  where
    pl.dup_type in ('PushEvent')
    and (
      pl.head = cf.sha
      or pl.commit = cf.sha
    )
  union select cf.sha,
    pr.event_id,
    pr.dup_repo_name || '/' || cf.path as path,
    cf.dt,
    cf.size,
    pr.dup_repo_id,
    pr.dup_repo_name,
    pr.dup_type,
    pr.dup_created_at
  from
    gha_pull_requests pr,
    gha_commits_files cf
  where
    pr.dup_type in ('PullRequestReviewCommentEvent', 'PullRequestEvent')
    and (
      pr.head_sha = cf.sha
      or pr.merge_commit_sha = cf.sha
    )
  ) sub
left join gha_events_commits_files ecf
on
  sub.sha = ecf.sha
  and sub.path = ecf.path
  and sub.event_id = ecf.event_id
where
  ecf.sha is null
on conflict do nothing
;
