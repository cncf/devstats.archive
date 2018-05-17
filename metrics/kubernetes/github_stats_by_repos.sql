with matching as (
  select event_id
  from
    gha_texts
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null
), reviews as (
  select id as event_id
  from
    gha_events
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and type in ('PullRequestReviewCommentEvent')
)
select 'gstat_r_commits,' || r.alias as repo,
  round(count(distinct c.sha) / {{n}}, 2) as metric
from
  gha_repos r,
  gha_commits c
where
  r.name = c.dup_repo_name
  and c.dup_created_at >= '{{from}}'
  and c.dup_created_at < '{{to}}'
  and (lower(c.dup_actor_login) {{exclude_bots}})
group by
  r.alias
union select 'gstat_r_iclosed,' || r.alias as repo,
  round(count(distinct i.id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.closed_at >= '{{from}}'
  and i.closed_at < '{{to}}'
group by
  r.alias
union select 'gstat_r_iopened,' || r.alias as repo,
  round(count(distinct i.id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
group by
  r.alias
union select 'gstat_r_propened,' || r.alias as repo,
  round(count(distinct pr.id) / {{n}}, 2) as metric
from
  gha_repos r,
  gha_pull_requests pr
where
  pr.dup_repo_id = r.id
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
group by
  r.alias
union select 'gstat_r_prmerged,' || r.alias as repo,
  round(count(distinct pr.id) / {{n}}, 2) as metric
from
  gha_pull_requests pr,
  gha_repos r
where
  r.name = pr.dup_repo_name
  and pr.merged_at is not null
  and pr.merged_at >= '{{from}}'
  and pr.merged_at < '{{to}}'
group by
  r.alias
union select 'gstat_r_prclosed,' || r.alias as repo,
  round(count(distinct pr.id) / {{n}}, 2) as metric
from
  gha_repos r,
  gha_pull_requests pr
where
  r.name = pr.dup_repo_name
  and pr.merged_at is null
  and pr.closed_at >= '{{from}}'
  and pr.closed_at < '{{to}}'
group by
  r.alias
union select 'gstat_r_prcomments,' || r.alias as repo,
  round(count(distinct i.event_id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = false
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.alias
union select 'gstat_r_prcommenters,' || r.alias as repo,
  count(distinct i.dup_actor_id) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = false
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.alias
union select 'gstat_r_icomments,' || r.alias as repo,
  round(count(distinct i.event_id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = true
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.alias
union select 'gstat_r_icommenters,' || r.alias as repo,
  count(distinct i.dup_actor_id) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = true
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.alias
union select 'gstat_r_reviewers,' || r.alias as repo,
    count(distinct e.dup_actor_login) as metric
  from
    gha_repos r,
    gha_events e
  where
    e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and label_name in ('lgtm', 'approved')
      group by
        issue_id
      union select event_id from matching
      union select event_id from reviews
    )
group by
  r.alias
order by
  repo asc
;
