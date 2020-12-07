with bots as(
  select login from gha_actors where not lower(login) {{exclude_bots}}
)
select
  sub.repo_group,
  sub.merger,
  count(distinct sub.id) as prs
from (
  select 'hpr_merger,' || r.repo_group as repo_group,
    coalesce('*bot: ' || b.login || ' *', pr.dupn_merged_by_login) as merger,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    bots b
  on
    pr.dupn_merged_by_login = b.login
  where
    {{period:pr.merged_at}}
    and pr.dup_repo_id = r.id
    and pr.dup_repo_name = r.name
    and pr.dupn_merged_by_login is not null
    and pr.merged_at is not null
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.merger
having
  count(distinct sub.id) >= 1
union select 'hpr_auth,All' as repo_group,
  coalesce('*bot: ' || b.login || ' *', pr.dupn_merged_by_login) as merger,
  count(distinct pr.id) as prs
from
  gha_pull_requests pr
left join
  bots b
on
  pr.dupn_merged_by_login = b.login
where
  {{period:pr.merged_at}}
  and pr.dupn_merged_by_login is not null
  and pr.merged_at is not null
group by
  pr.dupn_merged_by_login,
  b.login
having
  count(distinct pr.id) >= 1
order by
  prs desc,
  repo_group asc,
  merger asc
;
