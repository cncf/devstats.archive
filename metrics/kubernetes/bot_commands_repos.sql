with matching as (
  select cmd,
    eid,
    repo
  from (
    select regexp_replace(
      lower(
        substring(
          t.body from '(?i)(?:^|\s)+(/(approve|approve\s+no-issue|approve\s+cancel|area|remove\s+area|assign|unassign|cc|uncc|close|reopen|hold|hold\s+cancel|joke|kind|remove-kind|lgtm|lgtm\s+cancel|ok-to-test|test|test\s+all|retest|priority|remove-priority|sig|remove-sig|release-note|release-note-action-required|release-note-none|lifecycle))(?:$|\s)+'
        )
      ),
      '\s+',
      ' ',
      'g'
      ) as cmd,
      t.event_id as eid,
      t.repo_name as repo
    from
      gha_texts t
    where
      t.created_at >= '{{from}}'
      and t.created_at < '{{to}}'
      and (lower(t.actor_login) {{exclude_bots}})
      and t.repo_name in (select repo_name from trepos)
    ) sub
  where
    sub.cmd is not null
)
select
  sub.command,
  sub.count_value
from (
  select 'bot_cmds,' || substring(cmd from 1) || '`All' as command,
    round(count(distinct eid) / {{n}}, 2) as count_value
  from
    matching
  group by
    cmd
  union select 'bot_cmds,' || substring(cmd from 1) || '`' || repo as command,
    round(count(distinct eid) / {{n}}, 2) as count_value
  from
    matching
  group by
    cmd,
    repo
  ) sub
order by
  count_value desc,
  command asc;
