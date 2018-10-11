select
  a.login as actor,
  a.name as name,
  ae.email as email,
  aa.company_name as employer,
  case date_part('year', aa.dt_from) when 1970 then '-' else to_char(aa.dt_from, 'MM/DD/YYYY') end as date_from,
  case date_part('year', aa.dt_to) when 2099 then '-' else to_char(aa.dt_to, 'MM/DD/YYYY') end as date_to
from
  gha_actors a,
  gha_actors_emails ae,
  gha_actors_affiliations aa
where
  a.id = ae.actor_id
  and a.id = aa.actor_id
  and aa.company_name in ({{companies}})
  and aa.company_name != ''
order by
  a.name asc,
  ae.email asc,
  aa.dt_from asc
;
