with actors as (
  select sub.login,
    sub.cnt
  from (
    select login,
      count(distinct id) as cnt
    from
      gha_actors
    group by
      login
  ) sub
where
  sub.cnt > 1
order by
  sub.cnt desc
)
select
  m.login,
  m.cnt,
  a.id,
  aa.*
from
  actors m,
  gha_actors a
left join
  gha_actors_affiliations aa
on
  a.id = aa.actor_id
where
  m.login = a.login
  -- and aa.company_name is not null
order by
  m.cnt desc,
  m.login asc,
  a.id asc,
  aa.dt_from asc
;
