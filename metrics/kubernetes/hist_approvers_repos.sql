with matching as (
  select distinct event_id
  from
    gha_texts
  where
    {{period:created_at}}
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:approve)\s*(?:\n|\r|$)') is not null
)
select
  'hdev_approves,' || sub.repo || '_All' as metric,
  sub.actor || '$$$' || sub.company as actor_and_company,
  count(distinct sub.id) as approves
from (
  select e.dup_repo_name as repo,
    e.dup_actor_login as actor,
    coalesce(aa.company_name, '') as company,
    e.id
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (lower(e.dup_actor_login) {{exclude_bots}})
    and e.id in (select distinct event_id from matching)
    and e.dup_repo_name in (select repo_name from trepos)
    ) sub
group by
  sub.repo,
  sub.actor,
  sub.company
having
  count(distinct sub.id) >= 1
union select 'hdev_approves,All_All' as metric,
  e.dup_actor_login || '$$$' || coalesce(aa.company_name, '') as actor_and_company,
  count(distinct e.id) as approves
from
  gha_events e
left join
  gha_actors_affiliations aa
on
  aa.actor_id = e.actor_id
  and aa.dt_from <= e.created_at
  and aa.dt_to > e.created_at
where
  e.id in (select distinct event_id from matching)
  and (lower(e.dup_actor_login) {{exclude_bots}})
group by
  e.dup_actor_login,
  aa.company_name
having
  count(distinct id) >= 1
union select 'hdev_approves,All_' || a.country_name as metric,
  a.login || '$$$' || coalesce(aa.company_name, '') as actor_and_company,
  count(distinct e.id) as approves
from
  gha_actors a,
  gha_events e
left join
  gha_actors_affiliations aa
on
  aa.actor_id = e.actor_id
  and aa.dt_from <= e.created_at
  and aa.dt_to > e.created_at
where
  (e.actor_id = a.id or e.dup_actor_login = a.login)
  and e.id in (select distinct event_id from matching)
  and (lower(a.login) {{exclude_bots}})
  and a.country_name is not null
group by
  a.country_name,
  aa.company_name,
  a.login
having
  count(distinct e.id) >= 1
union select 'hdev_approves,' || sub.repo || '_' || sub.country as metric,
  sub.actor || '$$$' || sub.company as actor_and_company,
  count(distinct sub.id) as approves
from (
  select e.dup_repo_name as repo,
    a.country_name as country,
    a.login as actor,
    coalesce(aa.company_name, '') as company,
    e.id
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and (lower(a.login) {{exclude_bots}})
    and e.id in (select distinct event_id from matching)
    and e.dup_repo_name in (select repo_name from trepos)
    ) sub
where
  sub.country is not null
group by
  sub.repo,
  sub.country,
  sub.company,
  sub.actor
having
  count(distinct sub.id) >= 1
order by
  approves desc,
  metric asc,
  actor_and_company asc
;
