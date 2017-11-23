select
  string_agg(sub1.login, ',')
from (
  select
    distinct sub2.login
  from (
    select login
    from
      gha_actors
    union select dup_actor_login
    from
      gha_events
    ) sub2
  order by
    login
  ) sub1
;
