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
      range between current row
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
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at >= now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        committer_id as actor_id
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
), prev12_contributors as (
  select distinct r.repo_group,
    e.actor_id
  from (
      select repo_id,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at < now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at < now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at < now() - '1 year'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.repo_id
  group by
    r.repo_group,
    e.actor_id
), prev6_contributors as (
  select distinct r.repo_group,
    e.actor_id
  from (
      select repo_id,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at < now() - '6 months'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at < now() - '6 months'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at < now() - '6 months'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.repo_id
  group by
    r.repo_group,
    e.actor_id
), prev3_contributors as (
  select distinct r.repo_group,
    e.actor_id
  from (
      select repo_id,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at < now() - '3 months'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at < now() - '3 months'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at < now() - '3 months'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.repo_id
  group by
    r.repo_group,
    e.actor_id
), new12_contributors as (
  select r.repo_group,
    count(distinct e.actor_id) as ncontrib12
  from (
      select repo_id,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at >= now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e
  join
    gha_repos r
  on
    r.id = e.repo_id
    and r.repo_group is not null
  left join
    prev12_contributors pc
  on
    r.repo_group = pc.repo_group
    and e.actor_id = pc.actor_id
  where
    pc.actor_id is null
  group by
    r.repo_group
), new6_contributors as (
  select r.repo_group,
    count(distinct e.actor_id) as ncontrib6,
    count(distinct e.actor_id) filter (where e.created_at < now() - '3 months'::interval) as ncontribp3
  from (
      select repo_id,
        created_at,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at >= now() - '6 months'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '6 months'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at >= now() - '6 months'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e
  join
    gha_repos r
  on
    r.id = e.repo_id
    and r.repo_group is not null
  left join
    prev6_contributors pc
  on
    r.repo_group = pc.repo_group
    and e.actor_id = pc.actor_id
  where
    pc.actor_id is null
  group by
    r.repo_group
), new3_contributors as (
  select r.repo_group,
    count(distinct e.actor_id) as ncontrib3
  from (
      select repo_id,
        actor_id
      from
        gha_events
      where
        type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent')
        and created_at >= now() - '3 months'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '3 months'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and dup_created_at >= now() - '3 months'::interval
        and (lower(dup_committer_login) {{exclude_bots}})
    ) e
  join
    gha_repos r
  on
    r.id = e.repo_id
    and r.repo_group is not null
  left join
    prev3_contributors pc
  on
    r.repo_group = pc.repo_group
    and e.actor_id = pc.actor_id
  where
    pc.actor_id is null
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
        dup_actor_id as actor_id
      from
        gha_commits
      where
        dup_created_at >= now() - '1 year'::interval
        and (lower(dup_actor_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and dup_created_at >= now() - '1 year'::interval
        and (lower(dup_author_login) {{exclude_bots}})
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id
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
), prs_closed as (
  select r.repo_group,
    count(distinct pr.id) as pr12,
    count(distinct pr.id) filter (where pr.closed_at >= now() - '6 months'::interval) as pr6,
    count(distinct pr.id) filter (where pr.closed_at >= now() - '3 months'::interval) as pr3,
    count(distinct pr.id) filter (where pr.closed_at >= now() - '6 months'::interval and pr.closed_at < now() - '3 months'::interval) as prp3
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.repo_group is not null
    and pr.closed_at is not null
    and r.id = pr.dup_repo_id
    and pr.closed_at >= now() - '1 year'::interval
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
), issues_opened as (
  select r.repo_group,
    count(distinct i.id) as i12,
    count(distinct i.id) filter (where i.created_at >= now() - '6 months'::interval) as i6,
    count(distinct i.id) filter (where i.created_at >= now() - '3 months'::interval) as i3,
    count(distinct i.id) filter (where i.created_at >= now() - '6 months'::interval and i.created_at < now() - '3 months'::interval) as ip3
  from
    gha_issues i,
    gha_repos r
  where
    r.repo_group is not null
    and i.is_pull_request = false
    and r.id = i.dup_repo_id
    and i.created_at >= now() - '1 year'::interval
  group by
    r.repo_group
), issues_closed as (
  select r.repo_group,
    count(distinct i.id) as i12,
    count(distinct i.id) filter (where i.closed_at >= now() - '6 months'::interval) as i6,
    count(distinct i.id) filter (where i.closed_at >= now() - '3 months'::interval) as i3,
    count(distinct i.id) filter (where i.closed_at >= now() - '6 months'::interval and i.closed_at < now() - '3 months'::interval) as ip3
  from
    gha_issues i,
    gha_repos r
  where
    r.repo_group is not null
    and i.is_pull_request = false
    and i.closed_at is not null
    and r.id = i.dup_repo_id
    and i.closed_at >= now() - '1 year'::interval
  group by
    r.repo_group
), issue_ratio as (
  select io.repo_group,
    case ic.i3 when 0 then -1.0 else io.i3::float / ic.i3::float end as r3,
    case ic.ip3 when 0 then -1.0 else io.ip3::float / ic.ip3::float end as rp3
  from
    issues_opened io,
    issues_closed ic
  where
    io.repo_group = ic.repo_group
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
), pr_ratio as (
  select po.repo_group,
    case pc.pr3 when 0 then -1.0 else po.pr3::float / pc.pr3::float end as r3,
    case pc.prp3 when 0 then -1.0 else po.prp3::float / pc.prp3::float end as rp3
  from
    prs_opened po,
    prs_closed pc
  where
    po.repo_group = pc.repo_group
), commits_counts as (
  select r.repo_group,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.dup_created_at >= now() - '3 months'::interval) as n3
  from
    gha_commits e,
    gha_repos r
  where
    r.repo_group is not null
    and r.id = e.dup_repo_id
    and e.dup_created_at >= now() - '1 year'::interval
    and (
      (lower(e.dup_actor_login) {{exclude_bots}})
      or (lower(e.dup_author_login) {{exclude_bots}})
      or (lower(e.dup_committer_login) {{exclude_bots}})
    )
  group by
    r.repo_group
), known_commits_actors_counts as (
  select r.repo_group,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and a.company_name != 'NotFound'
    and a.company_name != '(Unknown)'
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group
), known_commits_authors_counts as (
  select r.repo_group,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and a.company_name != 'NotFound'
    and a.company_name != '(Unknown)'
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group
), known_commits_committers_counts as (
  select r.repo_group,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and a.company_name != 'NotFound'
    and a.company_name != '(Unknown)'
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group
), company_commits_actors_counts as (
  select r.repo_group,
    a.company_name,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group,
    a.company_name
), company_commits_authors_counts as (
  select r.repo_group,
    a.company_name,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group,
    a.company_name
), company_commits_committers_counts as (
  select r.repo_group,
    a.company_name,
    count(distinct e.sha) as n12,
    count(distinct e.sha) filter (where e.created_at >= now() - '3 months'::interval) as n3
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '1 year'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and a.company_name != ''
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group,
    a.company_name
), top_all_actors_3 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(a.n3) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_actors_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_actors_3 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(k.n3) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_actors_counts k,
      company_commits_actors_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_all_authors_3 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(a.n3) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_authors_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_authors_3 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(k.n3) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_authors_counts k,
      company_commits_authors_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_all_committers_3 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(a.n3) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_committers_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_committers_3 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n3) over companies_by_commits as c,
      first_value(k.n3) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_committers_counts k,
      company_commits_committers_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n3 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_all_actors_12 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(a.n12) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_actors_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_actors_12 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(k.n12) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_actors_counts k,
      company_commits_actors_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_all_authors_12 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(a.n12) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_authors_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_authors_12 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(k.n12) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_authors_counts k,
      company_commits_authors_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_all_committers_12 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(a.n12) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_committers_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_committers_12 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n12) over companies_by_commits as c,
      first_value(k.n12) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_committers_counts k,
      company_commits_committers_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n12 desc
        range between unbounded preceding
        and current row
      )
  ) i
), repo_groups as (
  select distinct repo_group
  from
    gha_repos
  where
    repo_group is not null
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
union select 'phealth,' || repo_group || ',cpr3' as name,
  'PRs: Number of PRs closed in the last 3 months',
  now(),
  0.0,
  pr3::text
from
  prs_closed
union select 'phealth,' || repo_group || ',cpr6' as name,
  'PRs: Number of PRs closed in the last 6 months',
  now(),
  0.0,
  pr6::text
from
  prs_closed
union select 'phealth,' || repo_group || ',cpr12' as name,
  'PRs: Number of PRs closed in the last 12 months',
  now(),
  0.0,
  pr12::text
from
  prs_closed
union select 'phealth,' || repo_group || ',cprp3' as name,
  'PRs: Number of PRs closed in the last 3 months (previous 3 months)',
  now(),
  0.0,
  prp3::text
from
  prs_closed
union select 'phealth,' || repo_group || ',cpr' as name,
  'PRs: Number of PRs closed in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case pr3 > prp3 when true then 'Up' else case pr3 < prp3 when true then 'Down' else 'Flat' end end
from
  prs_closed
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
  'Issues: Median time to respond to issues',
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
union select 'phealth,' || repo_group || ',pro2c' as name,
  'PRs: Opened to closed rate in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case r3 < 0 or rp3 < 0 when true then '-' else case r3 > rp3 when true then 'Up' else case r3 < rp3 when true then 'Down' else 'Flat' end end end
from
  pr_ratio
union select 'phealth,' || po.repo_group || ',pro2c3' as name,
  'PRs: Opened to closed rate in the last 3 months',
  now(),
  0.0,
  case pc.pr3 when 0 then '-' else round(po.pr3::numeric / pc.pr3::numeric, 2)::text end
from
  prs_opened po,
  prs_closed pc
where
  po.repo_group = pc.repo_group
union select 'phealth,' || po.repo_group || ',pro2cp3' as name,
  'PRs: Opened to closed rate in the last 3 months (previous 3 months)',
  now(),
  0.0,
  case pc.prp3 when 0 then '-' else round(po.prp3::numeric / pc.prp3::numeric, 2)::text end
from
  prs_opened po,
  prs_closed pc
where
  po.repo_group = pc.repo_group
union select 'phealth,' || po.repo_group || ',pro2c6' as name,
  'PRs: Opened to closed rate in the last 6 months',
  now(),
  0.0,
  case pc.pr6 when 0 then '-' else round(po.pr6::numeric / pc.pr6::numeric, 2)::text end
from
  prs_opened po,
  prs_closed pc
where
  po.repo_group = pc.repo_group
union select 'phealth,' || po.repo_group || ',pro2c12' as name,
  'PRs: Opened to closed rate in the last 12 months',
  now(),
  0.0,
  case pc.pr12 when 0 then '-' else round(po.pr12::numeric / pc.pr12::numeric, 2)::text end
from
  prs_opened po,
  prs_closed pc
where
  po.repo_group = pc.repo_group
union select 'phealth,' || repo_group || ',oi3' as name,
  'Issues: Number of issues opened in the last 3 months',
  now(),
  0.0,
  i3::text
from
  issues_opened
union select 'phealth,' || repo_group || ',oi6' as name,
  'Issues: Number of issues opened in the last 6 months',
  now(),
  0.0,
  i6::text
from
  issues_opened
union select 'phealth,' || repo_group || ',oi12' as name,
  'Issues: Number of issues opened in the last 12 months',
  now(),
  0.0,
  i12::text
from
  issues_opened
union select 'phealth,' || repo_group || ',oip3' as name,
  'Issues: Number of issues opened in the last 3 months (previous 3 months)',
  now(),
  0.0,
  ip3::text
from
  issues_opened
union select 'phealth,' || repo_group || ',oi' as name,
  'Issues: Number of issues opened in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case i3 > ip3 when true then 'Up' else case i3 < ip3 when true then 'Down' else 'Flat' end end
from
  issues_opened
union select 'phealth,' || repo_group || ',ci3' as name,
  'Issues: Number of issues closed in the last 3 months',
  now(),
  0.0,
  i3::text
from
  issues_closed
union select 'phealth,' || repo_group || ',ci6' as name,
  'Issues: Number of issues closed in the last 6 months',
  now(),
  0.0,
  i6::text
from
  issues_closed
union select 'phealth,' || repo_group || ',ci12' as name,
  'Issues: Number of issues closed in the last 12 months',
  now(),
  0.0,
  i12::text
from
  issues_closed
union select 'phealth,' || repo_group || ',cip3' as name,
  'Issues: Number of issues closed in the last 3 months (previous 3 months)',
  now(),
  0.0,
  ip3::text
from
  issues_closed
union select 'phealth,' || repo_group || ',ci' as name,
  'Issues: Number of issues closed in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case i3 > ip3 when true then 'Up' else case i3 < ip3 when true then 'Down' else 'Flat' end end
from
  issues_closed
union select 'phealth,' || repo_group || ',io2c' as name,
  'Issues: Opened to closed rate in the last 3 months vs. previous 3 months',
  now(),
  0.0,
  case r3 < 0 or rp3 < 0 when true then '-' else case r3 > rp3 when true then 'Up' else case r3 < rp3 when true then 'Down' else 'Flat' end end end
from
  issue_ratio
union select 'phealth,' || io.repo_group || ',io2c3' as name,
  'Issues: Opened to closed rate in the last 3 months',
  now(),
  0.0,
  case ic.i3 when 0 then '-' else round(io.i3::numeric / ic.i3::numeric, 2)::text end
from
  issues_opened io,
  issues_closed ic
where
  io.repo_group = ic.repo_group
union select 'phealth,' || io.repo_group || ',io2cp3' as name,
  'Issues: Opened to closed rate in the last 3 months (previous 3 months)',
  now(),
  0.0,
  case ic.ip3 when 0 then '-' else round(io.ip3::numeric / ic.ip3::numeric, 2)::text end
from
  issues_opened io,
  issues_closed ic
where
  io.repo_group = ic.repo_group
union select 'phealth,' || io.repo_group || ',io2c6' as name,
  'Issues: Opened to closed rate in the last 6 months',
  now(),
  0.0,
  case ic.i6 when 0 then '-' else round(io.i6::numeric / ic.i6::numeric, 2)::text end
from
  issues_opened io,
  issues_closed ic
where
  io.repo_group = ic.repo_group
union select 'phealth,' || io.repo_group || ',io2c12' as name,
  'Issues: Opened to closed rate in the last 12 months',
  now(),
  0.0,
  case ic.i12 when 0 then '-' else round(io.i12::numeric / ic.i12::numeric, 2)::text end
from
  issues_opened io,
  issues_closed ic
where
  io.repo_group = ic.repo_group
union select 'phealth,' || repo_group || ',ncontr3' as name,
  'Contributors: Number of new contributors in the last 3 months',
  now(),
  0.0,
  ncontrib3::text
from
  new3_contributors
union select 'phealth,' || repo_group || ',ncontr6' as name,
  'Contributors: Number of new contributors in the last 6 months',
  now(),
  0.0,
  ncontrib6::text
from
  new6_contributors
union select 'phealth,' || repo_group || ',ncontr12' as name,
  'Contributors: Number of new contributors in the last 12 months',
  now(),
  0.0,
  ncontrib12::text
from
  new12_contributors
union select 'phealth,' || repo_group || ',ncontrp3' as name,
  'Contributors: Number of new contributors in the last 3 months (last 3 months)',
  now(),
  0.0,
  ncontribp3::text
from
  new6_contributors
union select 'phealth,' || n.repo_group || ',ncontr' as name,
  'Contributors: Number of new contributors in the last 3 months vs. last 3 months',
  now(),
  0.0,
  case n.ncontrib3 > p.ncontribp3 when true then 'Up' else case n.ncontrib3 < p.ncontribp3 when true then 'Down' else 'Flat' end end
from
  new3_contributors n,
  new6_contributors p
where
  n.repo_group = p.repo_group
union select 'phealth,' || rg.repo_group || ',topcompknact3' as name,
  'Companies: Percent of known commits pushers from top committing company (last 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_actors_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallact3' as name,
  'Companies: Percent of all commits pushers from top committing company (last 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_actors_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompknauth3' as name,
  'Companies: Percent of known commits authors from top committing company (last 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_authors_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallauth3' as name,
  'Companies: Percent of all commits authors from top committing company (last 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_authors_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompkncom3' as name,
  'Companies: Percent of known commits from top committing company (previous 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_committers_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallcom3' as name,
  'Companies: Percent of all commits from top committing company (previous 3 months)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_committers_3 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompknact12' as name,
  'Companies: Percent of known commits pushers from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_actors_12 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallact12' as name,
  'Companies: Percent of all commits pushers from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_actors_12 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompknauth12' as name,
  'Companies: Percent of known commits authors from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_authors_12 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallauth12' as name,
  'Companies: Percent of all commits authors from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_authors_12 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompkncom12' as name,
  'Companies: Percent of known commits from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_known_committers_12 t
on
  rg.repo_group = t.repo_group
union select 'phealth,' || rg.repo_group || ',topcompallcom12' as name,
  'Companies: Percent of all commits from top committing company (last year)',
  now(),
  0.0,
  coalesce(t.top, '-')
from
  repo_groups rg
left join
  top_all_committers_12 t
on
  rg.repo_group = t.repo_group
;
