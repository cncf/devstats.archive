select
  'bot_commands,' || substring(cmd from 2) as command,
  count(*) as count_value
from
  (
    select lower(
        substring(
          body from '(?i)(?:^|\s)+(/[a-zA-Z]+)(?:$|\s)+'
        )
      ) as cmd
    from
      gha_texts
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
  ) sel
where
  sel.cmd is not null
group by
  sel.cmd
having
  count(*) >= 5
order by
  count_value desc,
  sel.cmd asc;
