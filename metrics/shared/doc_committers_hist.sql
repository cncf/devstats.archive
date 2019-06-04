select 
  'hcom,' || sub.metric as metric,
  sub.company as name,
  sub.value as value
from (
  select 'Documentation commits' as metric,
    affs.company_name as company,
    count(distinct c.sha) as value
  from
    gha_events_commits_files ecf,
    gha_commits c
  left join
    gha_actors_affiliations affs
  on
    c.author_id = affs.actor_id
    and affs.dt_from <= c.dup_created_at
    and affs.dt_to > c.dup_created_at
    and affs.company_name != ''
  where
    c.sha = ecf.sha
    and (ecf.path like '%.md' or ecf.path like '%.MD')
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  group by
    affs.company_name
  union select 'Documentation committers' as metric,
    affs.company_name as company,
    count(distinct c.author_id) as value
  from
    gha_events_commits_files ecf,
    gha_commits c
  left join
    gha_actors_affiliations affs
  on
    c.author_id = affs.actor_id
    and affs.dt_from <= c.dup_created_at
    and affs.dt_to > c.dup_created_at
    and affs.company_name != ''
  where
    c.sha = ecf.sha
    and (ecf.path like '%.md' or ecf.path like '%.MD')
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  group by
    affs.company_name
  union select 'Documentation commits' as metric,
    'All' as company,
    count(distinct c.sha) as value
  from
    gha_events_commits_files ecf,
    gha_commits c
  where
    c.sha = ecf.sha
    and (ecf.path like '%.md' or ecf.path like '%.MD')
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select 'Documentation committers' as metric,
    'All' as company,
    count(distinct c.author_id) as value
  from
    gha_events_commits_files ecf,
    gha_commits c
  where
    c.sha = ecf.sha
    and (path like '%.md' or path like '%.MD')
    and {{period:c.dup_created_at}}
    and (lower(dup_author_login) {{exclude_bots}})
  ) sub
where
  sub.company is not null
order by
  metric asc,
  value desc,
  name asc
;
