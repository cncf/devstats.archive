-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set alias = name;

update gha_repos
set repo_group = 'gnatsd', alias = 'gnatsd'
where name in (
  'nats-io/gnatsd',
  'apcera/gnatsd',
  'gnatsd'
);

update gha_repos
set repo_group = 'go-nats', alias = 'go-nats'
where name in (
  'nats-io/go-nats',
  'apcera/nats',
  'nats'
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
