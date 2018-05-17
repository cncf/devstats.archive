select
  sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as activity
from (
  select 'act,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    ev.id
  from
    gha_repos r,
    gha_events ev
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = ev.id
  where
    r.name = ev.dup_repo_name
    and ev.created_at >= '{{from}}'
    and ev.created_at < '{{to}}'
    and (lower(ev.dup_actor_login) {{exclude_bots}})
    and ev.type not in ('WatchEvent', 'ForkEvent', 'ArtificialEvent')
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  activity desc,
  repo_group asc
;
