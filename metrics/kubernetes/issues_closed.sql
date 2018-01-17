select
  'issues_closed,All' as name,
  round(count(distinct id) / {{n}}, 2) as cnt
from
  gha_issues
where
  closed_at >= '{{from}}'
  and closed_at < '{{to}}'
union select sub.name,
  round(count(distinct sub.id) / {{n}}, 2) as cnt
from (
  select 'issues_closed,' || coalesce(ecf.repo_group, r.repo_group) as name,
    i.id
  from
    gha_repos r,
    gha_issues i
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i.event_id
  where
    i.dup_repo_id = r.id
    and i.closed_at >= '{{from}}'
    and i.closed_at < '{{to}}'
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  cnt desc,
  name asc
;
