-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set alias = name;

update gha_repos
set repo_group = 'rkt', alias = 'rkt'
where name in (
  'rocket',
  'rkt/rkt',
  'coreos/rkt',
  'coreos/rocket',
  'rktproject/rkt'
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
