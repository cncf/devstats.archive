-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set alias = name;

update gha_repos
set repo_group = 'opencontainers/runtime-spec', alias = 'opencontainers/runtime-spec'
where name in (
  'opencontainers/runtime-spec',
  'opencontainers/specs'
);

update gha_repos
set repo_group = 'opencontainers/runc.io', alias = 'opencontainers/runc.io'
where name in (
  'opencontainers/runc.io',
  'opencontainers/runcweb'
);

update gha_repos
set repo_group = 'opencontainers/runtime-tools', alias = 'opencontainers/runtime-tools'
where name in (
  'opencontainers/ocitools',
  'opencontainers/runtime-tools'
);

update gha_repos
set repo_group = 'opencontainers/selinux', alias = 'opencontainers/selinux'
where name in (
  'opencontainers/go-selinux',
  'opencontainers/selinux'
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
