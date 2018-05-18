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
select
  sub.repo_group,
  round(count(distinct sub.sha) / {{n}}, 2) as metric
from (
  select 'gstat_rgrp_commits,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  where
    r.name = c.dup_repo_name
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'gstat_rgrp_iclosed,' || r.repo_group as repo_group,
  round(count(distinct i.id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.closed_at >= '{{from}}'
  and i.closed_at < '{{to}}'
group by
  r.repo_group
union select 'gstat_rgrp_iopened,' || r.repo_group as repo_group,
  round(count(distinct i.id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
group by
  r.repo_group
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as metric
from (
    select 'gstat_rgrp_propened,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    pr.dup_repo_id = r.id
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as metric
from (
  select 'gstat_rgrp_prmerged,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    r.name = pr.dup_repo_name
    and pr.merged_at is not null
    and pr.merged_at >= '{{from}}'
    and pr.merged_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as metric
from (
  select 'gstat_rgrp_prclosed,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    r.name = pr.dup_repo_name
    and pr.merged_at is null
    and pr.closed_at >= '{{from}}'
    and pr.closed_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'gstat_rgrp_prcomments,' || r.repo_group as repo_group,
  round(count(distinct i.event_id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = false
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.repo_group
union select 'gstat_rgrp_prcommenters,' || r.repo_group as repo_group,
  count(distinct i.dup_actor_id) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = false
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.repo_group
union select 'gstat_rgrp_icomments,' || r.repo_group as repo_group,
  round(count(distinct i.event_id) / {{n}}, 2) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = true
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.repo_group
union select 'gstat_rgrp_icommenters,' || r.repo_group as repo_group,
  count(distinct i.dup_actor_id) as metric
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
  and i.dup_type = 'IssueCommentEvent'
  and i.is_pull_request = true
  and (lower(i.dup_actor_login) {{exclude_bots}})
group by
  r.repo_group
union select sub.repo_group,
  count(distinct sub.actor) as metric
from (
  select 'gstat_rgrp_reviewers,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
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
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  repo_group asc
;
