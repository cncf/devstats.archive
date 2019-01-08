with commits_counts as (
  select r.repo_group,
    count(e.sha) as n
  from (
      select dup_repo_id as repo_id,
        dup_created_at as created_at,
        sha
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        sha
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        dup_created_at as created_at,
        sha
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
    ) e,
    gha_repos r
  where
    r.repo_group is not null
    and r.repo_group = 'OPA'
    and r.id = e.repo_id
  group by
    r.repo_group
), known_commits_counts as (
  select r.repo_group,
    count(e.sha) as n
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and r.repo_group = 'OPA'
    and a.company_name != ''
    and a.company_name != 'NotFound'
    and a.company_name != '(Unknown)'
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group
), company_commits_counts as (
  select r.repo_group,
    a.company_name,
    count(e.sha) as n
  from (
      select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
      union select dup_repo_id as repo_id,
        sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '3 months'::interval
    ) e,
    gha_repos r,
    gha_actors_affiliations a
  where
    r.repo_group is not null
    and r.repo_group = 'OPA'
    and a.company_name != ''
    and r.id = e.repo_id
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    r.repo_group,
    a.company_name
), top_all_3 as (
  select i.repo_group,
    case i.a > 0 when true then round((i.c::numeric / i.a::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n) over companies_by_commits as c,
      first_value(a.n) over companies_by_commits as a,
      first_value(c.company_name) over companies_by_commits as cname
    from
      commits_counts a,
      company_commits_counts c
    where
      a.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n desc
        range between unbounded preceding
        and current row
      )
  ) i
), top_known_3 as (
  select i.repo_group,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 2)::text || '% ' || i.cname else '-' end as top
  from (
    select distinct c.repo_group,
      first_value(c.n) over companies_by_commits as c,
      first_value(k.n) over companies_by_commits as k,
      first_value(c.company_name) over companies_by_commits as cname
    from
      known_commits_counts k,
      company_commits_counts c
    where
      k.repo_group = c.repo_group
    window
      companies_by_commits as (
        partition by c.repo_group
        order by
          c.n desc
        range between unbounded preceding
        and current row
      )
  ) i
)
select * from company_commits_counts;
/*
select 'phealth,' || repo_group || ',topcompall3' as name,
  'Companies: Percent of known commits from top committing company',
  now(),
  0.0,
  top
from
  top_known_3
union select 'phealth,' || repo_group || ',topcompall3' as name,
  'Companies: Percent of all commits from top committing company',
  now(),
  0.0,
  top
from
  top_all_3
;*/
