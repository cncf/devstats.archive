select
  'docstats;All;comps,devs' as name,
  count(distinct affs.company_name) as n_companies,
  count(distinct c.author_id) as n_authors
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
  and c.dup_created_at >= '{{from}}'
  and c.dup_created_at < '{{to}}'
  and (lower(c.dup_author_login) {{exclude_bots}})
union select sub.name,
  count(distinct sub.company_name) as n_companies,
  count(distinct sub.author_id) as n_authors
from (
  select 'docstats;' || coalesce(ecf.repo_group, r.repo_group) || ';comps,devs' as name,
    affs.company_name,
    c.author_id
  from
    gha_events_commits_files ecf,
    gha_repos r,
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
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
    and c.dup_repo_id = r.id
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  n_companies desc,
  n_authors desc,
  name asc
;
