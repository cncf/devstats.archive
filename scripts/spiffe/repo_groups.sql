-- Add repository groups
update
  gha_repos r
set
  alias = coalesce((
    select i.name
    from
      gha_repos i,
      gha_events e
    where
      i.id = r.id
      and e.repo_id = r.id
    order by
      e.created_at desc
    limit 1
  ), name)
;
update gha_repos set repo_group = alias;

select
  repo_group,
  count(*) as number_of_repos
from
  gha_repos
where
  repo_group is not null
group by
  repo_group
order by
  number_of_repos desc,
  repo_group asc;
