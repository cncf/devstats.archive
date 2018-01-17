select
  'new_prs,All' as repo_group,
  round(count(distinct id) / {{n}}, 2) as new
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as new
from (
    select 'new_prs,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    pr.dup_repo_id = r.id
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  new desc,
  repo_group asc
;
