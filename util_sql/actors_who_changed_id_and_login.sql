select
  a1.id,
  a3.id,
  a1.login,
  a3.login
from
  gha_actors a1,
  gha_actors a2,
  gha_actors a3
where
  a1.id = a2.id
  and lower(a2.login) = lower(a3.login)
  and a1.id != a3.id
  and a1.login != a3.login
  -- and lower(a1.login) != lower(a3.login)
order by
  a1.login,
  a3.login
;
