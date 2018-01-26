-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set alias = name;

update gha_repos
set repo_group = 'Jaeger', alias = 'Jaeger'
where name in (
  'jaegertracing/jaeger',
  'uber/jaeger'
);

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
