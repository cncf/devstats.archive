-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set alias = name;

update gha_repos
set repo_group = 'Vitess', alias = 'Vitess'
where name in (
  'vitessio/vitess',
  'youtube/vitess',
  'vitess'
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
