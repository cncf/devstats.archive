-- Add repository groups
with repo_latest as (
  select sub.repo_id,
    sub.repo_name
  from (
    select repo_id,
      dup_repo_name as repo_name,
      row_number() over (partition by repo_id order by created_at desc, id desc) as row_num
    from
      gha_events
  ) sub
  where
    sub.row_num = 1
)
update
  gha_repos r
set
  alias = (
    select rl.repo_name
    from
      repo_latest rl
    where
      rl.repo_id = r.id
  )
where
  r.name like '%_/_%'
  and r.name not like '%/%/%'
;
update gha_repos set repo_group = alias;

update gha_repos
set repo_group = 'KEDA', alias = 'KEDA'
where name in (
  'kedacore/keda'
);

update gha_repos
set repo_group = 'kedacore/sample-dotnet-worker-servicebus-queue', alias = 'kedacore/sample-dotnet-worker-servicebus-queue'
where name in (
  'kedacore/sample-dotnet-worker-servicebus-queue',
  'tomkerkhove/sample-dotnet-queue-worker',
  'tomkerkhove/sample-dotnet-queue-worker-servicebus-queue',
  'tomkerkhove/sample-dotnet-worker-servicebus-queue'
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
