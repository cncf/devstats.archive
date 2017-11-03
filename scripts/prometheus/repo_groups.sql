-- Add repository groups
-- This is a stub, repo_group = repo name in Prometheus
update gha_repos set repo_group = name;

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

update gha_repos set alias = name;
update gha_repos set alias = 'prometheus' where name like '%prometheus';
