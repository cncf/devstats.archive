select
  a.id as ID,
  a.login as Author,
  a.name as Name,
  ae.email as Email,
  aa.company_name as Employer,
  to_char(aa.dt_from, 'YYYY-MM-DD') as From,
  to_char(aa.dt_to, 'YYYY-MM-DD') as To
from
  gha_actors a,
  gha_actors_emails ae,
  gha_actors_affiliations aa
where
  a.id = ae.actor_id
  and a.id = aa.actor_id
  and (
    aa.company_name = 'CNCF'
    or a.login = 'lukaszgryglicki'
  )
  and aa.company_name != ''
order by
  a.name asc,
  ae.email asc,
  aa.dt_from asc
;
