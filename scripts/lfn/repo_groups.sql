-- Add repository groups
update gha_repos set repo_group = name;

update gha_repos set repo_group = 'IO Visor' where org_login = 'iovisor';
update gha_repos set repo_group = 'Mininet' where org_login = 'mininet';
update gha_repos set repo_group = 'Open Networking' where org_login = 'opennetworkinglab';
update gha_repos set repo_group = 'Open Security' where org_login = 'opensecuritycontroller';
update gha_repos set repo_group = 'OpenSwitch' where org_login = 'open-switch';
update gha_repos set repo_group = 'p4language' where org_login = 'p4lang';
update gha_repos set repo_group = 'OpenBMP' where org_login = 'OpenBMP';
update gha_repos set repo_group = 'Tungsten Fabric' where org_login = 'tungstenfabric';
update gha_repos set repo_group = 'CORD' where org_login = 'opencord';
update gha_repos set repo_group = null where org_login is null;

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
  repo_group asc
;
