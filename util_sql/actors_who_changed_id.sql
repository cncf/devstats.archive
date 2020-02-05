with actors as (
  select sub.id,
    sub.cnt
  from (
    select id,
      count(distinct login) as cnt
    from
      gha_actors
    group by
      id
  ) sub
where
  sub.cnt > 1
order by
  sub.cnt desc
)
select
  m.id,
  a.login,
  m.cnt,
  aa.*
from
  actors m,
  gha_actors a
left join
  gha_actors_affiliations aa
on
  a.id = aa.actor_id
where
  m.id = a.id
order by
  m.cnt desc,
  m.id asc,
  a.login asc,
  aa.dt_from asc
;
