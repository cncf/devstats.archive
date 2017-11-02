select
  -- string_agg(sub.command, ',')
  sub.command
from (
  select substring(cmd from 2) as command,
    count(*) as count_value
  from
    (
      select regexp_replace(
        lower(
          substring(
            body from '(?i)(?:^|\s)+(/(approve|approve\s+no-issue|approve\s+cancel|area|remove\s+area|assign|unassign|cc|uncc|close|reopen|hold|hold\s+cancel|joke|kind|remove-kind|lgtm|lgtm\s+cancel|ok-to-test|test|test\s+all|retest|priority|remove-priority|sig|remove-sig|release-note|release-note-action-required|release-note-none))(?:$|\s)+'
          )
        ),
        '\s+',
        ' ',
        'g'
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
) sub
;
