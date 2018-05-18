with prev as (
  select distinct user_id
  from
    gha_issues
  where
    created_at >= date '{{from}}' - '3 months'::interval
    and created_at < '{{from}}'
    and is_pull_request = false
), prev_cnt as (
  select user_id, count(distinct id) as cnt
  from
    gha_issues
  where
    created_at < '{{from}}'
    and is_pull_request = false
  group by
    user_id
)
select
  'epis_iss;All;contrib,iss' as name,
  round(count(distinct i.user_id) / {{n}}, 2) as contributors,
  round(count(distinct i.id) / {{n}}, 2) as issues
from
  gha_issues i
left join
  prev_cnt pc
on
  pc.user_id = i.user_id
where
  i.is_pull_request = false
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
  and i.user_id not in (select user_id from prev)
  and (pc.user_id is null or pc.cnt <= 12)
union select sub.name,
  round(count(distinct sub.user_id) / {{n}}, 2) as contributors,
  round(count(distinct sub.id) / {{n}}, 2) as issues
from (
    select 'epis_iss;' || coalesce(ecf.repo_group, r.repo_group) || ';contrib,iss' as name,
    i.user_id,
    i.id
  from
    gha_repos r,
    gha_issues i
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i.event_id
  left join
    prev_cnt pc
  on
    pc.user_id = i.user_id
  where
    i.dup_repo_id = r.id
    and i.is_pull_request = false
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.user_id not in (select user_id from prev)
    and (pc.user_id is null or pc.cnt <= 12)
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  issues desc,
  name asc
;
