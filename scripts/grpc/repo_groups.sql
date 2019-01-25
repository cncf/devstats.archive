-- Add repository groups
-- This is a stub, repo_group = repo name in gRPC
update
  gha_repos r
set
  alias = coalesce((
    select e.dup_repo_name
    from
      gha_events e
    where
      e.repo_id = r.id
    order by
      e.created_at desc
    limit 1
  ), name)
;
update gha_repos set repo_group = alias;

update gha_repos set alias = 'grpc', repo_group = 'grpc' where name like '%grpc' or name = 'grpc/';

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
