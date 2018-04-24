select
  sub.repo_group,
  round(count(distinct sub.sha) / {{n}}, 2) as metric
from (
  select 'gh_stats_repo_groups_commits,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and (c.dup_actor_login {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
union select 'gh_stats_repo_groups_issues_closed,' || r.repo_group as repo_group,
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
union select 'gh_stats_repo_groups_issues_opened,' || r.repo_group as repo_group,
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
    select 'gh_stats_repo_groups_new_prs,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
  select 'gh_stats_repo_groups_prs_merged,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
order by
  repo_group asc
;
