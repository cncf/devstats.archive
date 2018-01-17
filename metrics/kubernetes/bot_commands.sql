create temp table matching as
select cmd, eid, repo_group
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
    coalesce(ecf.repo_group, r.repo_group) as repo_group
  from
    gha_repos r,
    gha_texts t
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = t.event_id
  where
    r.id = t.repo_id
    and t.created_at >= '{{from}}'
    and t.created_at < '{{to}}'
    and t.actor_login not in ('googlebot')
    and t.actor_login not like 'k8s-%'
    and t.actor_login not like '%-bot'
    and t.actor_login not like '%-robot'
  ) sub
where
  sub.repo_group is not null
  and sub.cmd is not null;

select
  'bot_commands,' || substring(cmd from 2) || '`All' as command,
  round(count(distinct eid) / {{n}}, 2) as count_value
from
  matching
group by
  cmd
union select 'bot_commands,' || substring(cmd from 2) || '`' || repo_group as command,
  round(count(distinct eid) / {{n}}, 2) as count_value
from
  matching
group by
  cmd,
  repo_group
order by
  count_value desc,
  command asc;

drop table matching;
