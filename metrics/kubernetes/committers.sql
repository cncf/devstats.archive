with commits_data as (
  select coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.dup_actor_id as actor_id,
    c.dup_actor_login as actor_login,
    aa.company_name as company
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.dup_actor_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.author_id as actor_id,
    c.dup_author_login as actor_login,
    aa.company_name as company
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.author_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.author_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select coalesce(ecf.repo_group, r.repo_group) as repo_group,
    c.sha,
    c.committer_id as actor_id,
    c.dup_committer_login as actor_login,
    aa.company_name as company
  from
    gha_repos r,
    gha_commits c
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = c.event_id
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.committer_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and c.committer_id is not null
    and c.dup_created_at >= '{{from}}'
    and c.dup_created_at < '{{to}}'
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
-- metric_All_All_All: commits_RepoGroup_Country_Company
select 
  'cs;commits_All_All_All;evs,acts' as metric,
  round(count(distinct sha) / {{n}}, 2) as evs,
  count(distinct actor_login) as acts
from 
  commits_data
union select  'cs;commits_' || repo_group || '_All_All;evs,acts' as metric,
  round(count(distinct sha) / {{n}}, 2) as evs,
  count(distinct actor_login) as acts
from 
  commits_data
where
  repo_group is not null
group by
  repo_group
union select 'cs;commits_All_' || a.country_name || '_All;evs,acts' as metric,
  round(count(distinct c.sha) / {{n}}, 2) as evs,
  count(distinct c.actor_login) as acts
from
  commits_data c,
  gha_actors a
where
  c.actor_id = a.id
  and a.country_name is not null
group by
  a.country_name
union select 'cs;commits_' || c.repo_group || '_' || a.country_name || '_All;evs,acts' as metric,
  round(count(distinct c.sha) / {{n}}, 2) as evs,
  count(distinct c.actor_login) as acts
from
  commits_data c,
  gha_actors a
where
  c.actor_id = a.id
  and a.country_name is not null
  and c.repo_group is not null
group by
  a.country_name,
  c.repo_group
union select 'cs;commits_All_All_' || company || ';evs,acts' as metric,
  round(count(distinct sha) / {{n}}, 2) as evs,
  count(distinct actor_login) as acts
from 
  commits_data
where
  company is not null
  and company in (select companies_name from tcompanies)
group by
  company
union select  'cs;commits_' || repo_group || '_All_' || company || ';evs,acts' as metric,
  round(count(distinct sha) / {{n}}, 2) as evs,
  count(distinct actor_login) as acts
from 
  commits_data
where
  repo_group is not null
  and company is not null
  and company in (select companies_name from tcompanies)
group by
  repo_group,
  company
union select 'cs;commits_All_' || a.country_name || '_' || c.company || ';evs,acts' as metric,
  round(count(distinct c.sha) / {{n}}, 2) as evs,
  count(distinct c.actor_login) as acts
from
  commits_data c,
  gha_actors a
where
  c.actor_id = a.id
  and a.country_name is not null
  and c.company is not null
  and c.company in (select companies_name from tcompanies)
group by
  a.country_name,
  c.company
union select 'cs;commits_' || c.repo_group || '_' || a.country_name || '_' || c.company || ';evs,acts' as metric,
  round(count(distinct c.sha) / {{n}}, 2) as evs,
  count(distinct c.actor_login) as acts
from
  commits_data c,
  gha_actors a
where
  c.actor_id = a.id
  and a.country_name is not null
  and c.repo_group is not null
  and c.company is not null
  and c.company in (select companies_name from tcompanies)
group by
  a.country_name,
  c.repo_group,
  c.company
/*
order by
  acts desc,
  evs desc
*/
;
