with commits_counts as (
  select count(distinct e.sha) as n
  from (
      select sha
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
    ) e
), company_commits_counts as (
  select a.company_name,
    count(distinct e.sha) as n
  from (
      select sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
    ) e,
    gha_actors_affiliations a
  where
    a.company_name != ''
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
  group by
    a.company_name
), known_commits_counts as (
  select count(distinct e.sha) as n
  from (
      select sha,
        dup_created_at as created_at,
        dup_actor_id as actor_id
      from
        gha_commits
      where
        (lower(dup_actor_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha,
        dup_created_at as created_at,
        author_id as actor_id
      from
        gha_commits
      where
        dup_author_login is not null
        and (lower(dup_author_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
      union select sha,
        dup_created_at as created_at,
        committer_id as actor_id
      from
        gha_commits
      where
        dup_committer_login is not null
        and (lower(dup_committer_login) {{exclude_bots}})
        and dup_created_at >= now() - '6 months'::interval
        and dup_repo_name not like 'cncf%'
        and dup_repo_name not like 'crosscloudci%'
    ) e,
    gha_actors_affiliations a
  where
    a.company_name != ''
    and a.company_name != 'NotFound'
    and a.company_name != '(Unknown)'
    and e.actor_id = a.actor_id
    and a.dt_from <= e.created_at
    and a.dt_to > e.created_at
), top_known as (
  select i.cn as company,
    case i.k > 0 when true then round((i.c::numeric / i.k::numeric) * 100.0, 3) else -1.0 end as percent
  from (
    select distinct c.n as c,
      k.n as k,
      c.company_name as cn
    from
      known_commits_counts k,
      company_commits_counts c
    order by
      c.n desc
  ) i
  limit
    {{lim}}
)
select * from top_known;
