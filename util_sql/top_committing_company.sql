with commits_counts as (
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
)
select 'phealth,' || repo_group || ',topcompknact3' as name,
  'Companies: Percent of known commits pushers from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_known_actors_3
union select 'phealth,' || repo_group || ',topcompallact3' as name,
  'Companies: Percent of all commits pushers from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_all_actors_3
union select 'phealth,' || repo_group || ',topcompknauth3' as name,
  'Companies: Percent of known commits authors from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_known_authors_3
union select 'phealth,' || repo_group || ',topcompallauth3' as name,
  'Companies: Percent of all commits authors from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_all_authors_3
union select 'phealth,' || repo_group || ',topcompkncom3' as name,
  'Companies: Percent of known commits from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_known_committers_3
union select 'phealth,' || repo_group || ',topcompallcom3' as name,
  'Companies: Percent of all commits from top committing company (previous 3 months)',
  now(),
  0.0,
  top
from
  top_all_committers_3
union select 'phealth,' || repo_group || ',topcompknact12' as name,
  'Companies: Percent of known commits pushers from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_known_actors_12
union select 'phealth,' || repo_group || ',topcompallact12' as name,
  'Companies: Percent of all commits pushers from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_all_actors_12
union select 'phealth,' || repo_group || ',topcompknauth12' as name,
  'Companies: Percent of known commits authors from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_known_authors_12
union select 'phealth,' || repo_group || ',topcompallauth12' as name,
  'Companies: Percent of all commits authors from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_all_authors_12
union select 'phealth,' || repo_group || ',topcompkncom12' as name,
  'Companies: Percent of known commits from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_known_committers_12
union select 'phealth,' || repo_group || ',topcompallcom12' as name,
  'Companies: Percent of all commits from top committing company (last year)',
  now(),
  0.0,
  top
from
  top_all_committers_12
;
