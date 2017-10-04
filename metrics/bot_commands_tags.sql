select
  -- string_agg(sub.command, ',')
  sub.command
from (
  select
    substring(cmd from 2) as command,
    count(*) as count_value
  from
    (
      select lower(
          substring(
            body from '(?i)(?:^|\s)+(/[a-zA-Z]+[a-zA-Z0-9]+)(?:$|\s)+'
          )
        ) as cmd
      from
        gha_texts
      where
        actor_login not in ('googlebot')
        and actor_login not like 'k8s-%'
        and actor_login not like '%-bot'
        and actor_login not like '%-robot'
    ) sel
  where
    sel.cmd is not null
  group by
    sel.cmd
  order by
    count_value desc,
    sel.cmd asc
  limit 25
) sub
;
