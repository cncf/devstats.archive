with projects as (
  select distinct period as project,
    repo,
    last_value(time) over projects_by_time as last_release_date,
    last_value(title) over projects_by_time as last_release_tag,
    last_value(description) over projects_by_time as last_release_desc
  from
    sannotations_shared
  where
    title != 'CNCF join date'
  window
    projects_by_time as (
      partition by period
      order by
        time asc
      range between unbounded preceding
      and unbounded following
    )
), contributors as (
  select r.repo_group,
    count(distinct e.actor_id) as contrib12,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '6 months'::interval) as contrib6,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '3 months'::interval) as contrib3,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '6 months'::interval and e.created_at < now() - '3 months'::interval) as contribp3
  from (
      select repo_id,
        created_at,
        actor_id,
        dup_actor_login as actor_login
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at >= now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        author_id as actor_id,
        dup_author_login as actor_login
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        committer_id as actor_id,
        dup_committer_login as actor_login
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.repo_id
  group by
    r.repo_group
), commits as (
  select r.repo_group,
    count(distinct e.sha) as comm12,
    count(distinct e.sha) filter (where e.created_at >= now() - '6 months'::interval) as comm6,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as comm3,
    count(distinct e.sha) filter (where e.created_at >= now() - '6 months'::interval and e.created_at < now() - '3 months'::interval) as commp3,
    count(distinct e.actor_id) as acomm12,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '6 months'::interval) as acomm6,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '3 months'::interval) as acomm3,
    count(distinct e.actor_id) filter (where e.created_at >= now() - '6 months'::interval and e.created_at < now() - '3 months'::interval) as acommp3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id,
        dup_actor_login as actor_login
      from
        gha_commits
      where
        dup_created_at >= now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id,
        dup_author_login as actor_login
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id,
        dup_committer_login as actor_login
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.repo_id
  group by
    r.repo_group
), prs_opened as (
  select r.repo_group,
    count(distinct pr.id) as pr12,
    count(distinct pr.id) filter (where pr.created_at >= now() - '6 months'::interval) as pr6,
    count(distinct pr.id) filter (where pr.created_at >= now() - '3 months'::interval) as pr3,
    count(distinct pr.id) filter (where pr.created_at >= now() - '6 months'::interval and pr.created_at < now() - '3 months'::interval) as prp3
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = pr.dup_repo_id
    and pr.created_at >= now() - '1 year'::interval
  group by
    r.repo_group
), prs_merged as (
  select r.repo_group,
    count(distinct pr.id) as pr12,
    count(distinct pr.id) filter (where pr.merged_at >= now() - '6 months'::interval) as pr6,
    count(distinct pr.id) filter (where pr.merged_at >= now() - '3 months'::interval) as pr3,
    count(distinct pr.id) filter (where pr.merged_at >= now() - '6 months'::interval and pr.merged_at < now() - '3 months'::interval) as prp3
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.repo_group is not null
    and pr.merged_at is not null
    and r.id = pr.dup_repo_id
    and pr.merged_at >= now() - '1 year'::interval
  group by
    r.repo_group
), recent_issues as (
  select distinct id,
    user_id,
    created_at
  from
    gha_issues
  where
    created_at >= now() - '6 months'::interval
), tdiffs as (
  select i2.updated_at - i.created_at as diff,
    r.repo_group
  from
    recent_issues i,
    gha_repos r,
    gha_issues i2
  where
    i.id = i2.id
    and r.name = i2.dup_repo_name
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.id
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
), react_time as (
  select repo_group,
    percentile_disc(0.15) within group (order by diff asc) as p15,
    percentile_disc(0.5) within group (order by diff asc) as med,
    percentile_disc(0.85) within group (order by diff asc) as p85
  from
    tdiffs
  where
    repo_group is not null
  group by
    repo_group
)
select
  'phealth,' || project || ',ltag' as name,
  'Releases: Last release',
  last_release_date,
  0.0,
  last_release_tag
from
  projects
union select
  'phealth,' || project || ',ldate' as name,
  'Releases: Last release date',
  last_release_date,
  0.0,
  to_char(last_release_date, 'MM/DD/YYYY')
from
  projects
union select
  'phealth,' || project || ',ldesc' as name,
  'Releases: Last release description',
  last_release_date,
  0.0,
  last_release_desc
from
  projects
union select 'phealth,' || r.repo_group || ',lcomm' as name,
  'Commits: Last commit date',
  max(c.dup_created_at),
  0.0,
  to_char(max(c.dup_created_at), 'MM/DD/YYYY HH12:MI:SS pm')
from
  gha_commits c,
  gha_repos r
where
  c.dup_repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'phealth,' || r.repo_group || ',lcommd' as name,
  'Commits: Days since last commit',
  max(c.dup_created_at),
  0.0,
  DATE_PART('day', now() - max(c.dup_created_at))::text || ' days'
from
  gha_commits c,
  gha_repos r
where
  c.dup_repo_id = r.id
  and r.repo_group is not null
group by
  r.repo_group
union select 'phealth,' || repo_group || ',acomm3' as name,
  'Committers: Number of committers in the last 3 months',
  now(),
  0.0,
  acomm3::text
from
  commits
union select 'phealth,' || repo_group || ',acomm6' as name,
  'Committers: Number of committers in the last 6 months',
  now(),
  0.0,
  acomm6::text
from
  commits
union select 'phealth,' || repo_group || ',acomm12' as name,
  'Committers: Number of committers in the last 12 months',
  now(),
  0.0,
  acomm12::text
from
  commits
union select 'phealth,' || repo_group || ',acommp3' as name,
  'Committers: Number of committers in the last 3 months (previous 3 months)',
  now(),
  0.0,
  acommp3::text
from
  commits
union select 'phealth,' || repo_group || ',acomm' as name,
  'Committers: Number of committers in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case acomm3 > acommp3 when true then 'Up' else case acomm3 < acommp3 when true then 'Down' else 'Flat' end end
from
  commits
union select 'phealth,' || repo_group || ',comm3' as name,
  'Commits: Number of commits in the last 3 months',
  now(),
  0.0,
  comm3::text
from
  commits
union select 'phealth,' || repo_group || ',comm6' as name,
  'Commits: Number of commits in the last 6 months',
  now(),
  0.0,
  comm6::text
from
  commits
union select 'phealth,' || repo_group || ',comm12' as name,
  'Commits: Number of commits in the last 12 months',
  now(),
  0.0,
  comm12::text
from
  commits
union select 'phealth,' || repo_group || ',commp3' as name,
  'Commits: Number of commits in the last 3 months (previous 3 months)',
  now(),
  0.0,
  commp3::text
from
  commits
union select 'phealth,' || repo_group || ',comm' as name,
  'Commits: Number of commits in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case comm3 > commp3 when true then 'Up' else case comm3 < commp3 when true then 'Down' else 'Flat' end end
from
  commits
union select 'phealth,' || repo_group || ',contr3' as name,
  'Contributors: Number of contributors in the last 3 months',
  now(),
  0.0,
  contrib3::text
from
  contributors
union select 'phealth,' || repo_group || ',contr6' as name,
  'Contributors: Number of contributors in the last 6 months',
  now(),
  0.0,
  contrib6::text
from
  contributors
union select 'phealth,' || repo_group || ',contr12' as name,
  'Contributors: Number of contributors in the last 12 months',
  now(),
  0.0,
  contrib12::text
from
  contributors
union select 'phealth,' || repo_group || ',contrp3' as name,
  'Contributors: Number of contributors in the last 3 months (previous 3 months)',
  now(),
  0.0,
  contribp3::text
from
  contributors
union select 'phealth,' || repo_group || ',contr' as name,
  'Contributors: Number of contributors in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case contrib3 > contribp3 when true then 'Up' else case contrib3 < contribp3 when true then 'Down' else 'Flat' end end
from
  contributors
union select 'phealth,' || repo_group || ',opr3' as name,
  'PRs: Number of PRs opened in the last 3 months',
  now(),
  0.0,
  pr3::text
from
  prs_opened
union select 'phealth,' || repo_group || ',opr6' as name,
  'PRs: Number of PRs opened in the last 6 months',
  now(),
  0.0,
  pr6::text
from
  prs_opened
union select 'phealth,' || repo_group || ',opr12' as name,
  'PRs: Number of PRs opened in the last 12 months',
  now(),
  0.0,
  pr12::text
from
  prs_opened
union select 'phealth,' || repo_group || ',oprp3' as name,
  'PRs: Number of PRs opened in the last 3 months (previous 3 months)',
  now(),
  0.0,
  prp3::text
from
  prs_opened
union select 'phealth,' || repo_group || ',opr' as name,
  'PRs: Number of PRs opened in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case pr3 > prp3 when true then 'Up' else case pr3 < prp3 when true then 'Down' else 'Flat' end end
from
  prs_opened
union select 'phealth,' || repo_group || ',mpr3' as name,
  'PRs: Number of PRs merged in the last 3 months',
  now(),
  0.0,
  pr3::text
from
  prs_merged
union select 'phealth,' || repo_group || ',mpr6' as name,
  'PRs: Number of PRs merged in the last 6 months',
  now(),
  0.0,
  pr6::text
from
  prs_merged
union select 'phealth,' || repo_group || ',mpr12' as name,
  'PRs: Number of PRs merged in the last 12 months',
  now(),
  0.0,
  pr12::text
from
  prs_merged
union select 'phealth,' || repo_group || ',mprp3' as name,
  'PRs: Number of PRs merged in the last 3 months (previous 3 months)',
  now(),
  0.0,
  prp3::text
from
  prs_merged
union select 'phealth,' || repo_group || ',mpr' as name,
  'PRs: Number of PRs merged in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case pr3 > prp3 when true then 'Up' else case pr3 < prp3 when true then 'Down' else 'Flat' end end
from
  prs_merged
union select 'phealth,' || repo_group || ',ip15' as name,
  'Issues: 15th percentile of time to respond to issues',
  now(),
  0.0,
  p15::text
from
  react_time
union select 'phealth,' || repo_group || ',imed' as name,
  'Issues: median time to respond to issues',
  now(),
  0.0,
  med::text
from
  react_time
union select 'phealth,' || repo_group || ',ip85' as name,
  'Issues: 85th percentile of time to respond to issues',
  now(),
  0.0,
  p85::text
from
  react_time
;
