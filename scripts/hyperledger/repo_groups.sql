-- Add repository groups
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

update
  gha_repos
set
  alias = 'Cello',
  repo_group = 'Cello'
where
  name like 'hyperledger/%cello%'
;

update
  gha_repos
set
  alias = 'Blockchain Explorer',
  repo_group = 'Blockchain Explorer'
where
  name in ('hyperledger/blockchain-explorer')
;

update
  gha_repos
set
  alias = 'Fabric',
  repo_group = 'Fabric'
where
  name like 'hyperledger/fabric%'
;

update
  gha_repos
set
  alias = 'Labs',
  repo_group = 'Labs'
where
  org_login in ('hyperledger-labs')
;

update
  gha_repos
set
  alias = 'Aries',
  repo_group = 'Aries'
where
  name like 'hyperledger/aries%'
;

update
  gha_repos
set
  alias = 'Burrow',
  repo_group = 'Burrow'
where
  name like 'hyperledger/burrow%'
;

update
  gha_repos
set
  alias = 'Caliper',
  repo_group = 'Caliper'
where
  name like 'hyperledger/caliper%'
;

update
  gha_repos
set
  alias = 'LMWG',
  repo_group = 'LMWG'
where
  name like 'hyperledger/education%'
;

update
  gha_repos
set
  alias = 'Grid',
  repo_group = 'Grid'
where
  name like 'hyperledger/grid%'
;

update
  gha_repos
set
  alias = 'WPWG',
  repo_group = 'WPWG'
where
  name like 'hyperledger/hyperledgerwp%'
;

update
  gha_repos
set
  alias = 'Indy',
  repo_group = 'Indy'
where
  name like 'hyperledger/indy%'
;

update
  gha_repos
set
  alias = 'Iroha',
  repo_group = 'Iroha'
where
  name like 'hyperledger/iroha%'
;

update
  gha_repos
set
  alias = 'PSWG',
  repo_group = 'PSWG'
where
  name like 'hyperledger/perf-and-scale%'
;

update
  gha_repos
set
  alias = 'Quilt',
  repo_group = 'Quilt'
where
  name like 'hyperledger/quilt%'
;

update
  gha_repos
set
  alias = 'Sawtooth',
  repo_group = 'Sawtooth'
where
  name like 'hyperledger/sawtooth%'
;

update
  gha_repos
set
  alias = 'Transact',
  repo_group = 'Transact'
where
  name like 'hyperledger-cicd/transact%'
;

update
  gha_repos
set
  alias = 'Ursa',
  repo_group = 'Ursa'
where
  name like 'hyperledger/ursa%'
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
  repo_group asc;
