select
  'num_stats;All;companies,developers' as name,
  count(distinct affs.company_name) as n_companies,
  count(distinct ev.dup_actor_login) as n_authors
from
  gha_events ev,
  gha_actors_affiliations affs
where
  ev.actor_id = affs.actor_id
  and affs.dt_from <= ev.created_at
  and affs.dt_to > ev.created_at
  and ev.created_at >= '{{from}}'
  and ev.created_at < '{{to}}'
  and affs.company_name not in ('Self')
union select
  'num_stats;' || r.repo_group || ';companies,developers' as name,
  count(distinct affs.company_name) as n_companies,
  count(distinct ev.dup_actor_login) as n_authors
from
  gha_events ev,
  gha_actors_affiliations affs,
  gha_repos r
where
  r.name = ev.dup_repo_name
  and r.repo_group is not null
  and ev.actor_id = affs.actor_id
  and affs.dt_from <= ev.created_at
  and affs.dt_to > ev.created_at
  and ev.created_at >= '{{from}}'
  and ev.created_at < '{{to}}'
  and affs.company_name not in ('Self')
group by
  r.repo_group
order by
  n_companies desc,
  n_authors desc,
  name asc
;
