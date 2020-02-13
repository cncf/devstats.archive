-- Clear current repo groups (taken from merge of all other projects)
-- This script is executed every hour

update
  gha_repos
set
  repo_group = null
;

-- Spinnaker
update
  gha_repos
set
  repo_group = 'Spinnaker'
where
  org_login in ('spinnaker')
;

-- Tekton
update
  gha_repos
set
  repo_group = 'Tekton'
where
  org_login in ('knative', 'tektoncd')
;

-- Jenkins
update
  gha_repos
set
  repo_group = 'Jenkins'
where
  org_login in ('jenkinsci')
;

-- Jenkins X
update
  gha_repos
set
  repo_group = 'Jenkins X'
where
  org_login in (
    'jenkins-x', 'jenkins-x-quickstarts', 'jenkins-x-apps',
    'jenkins-x-charts', 'jenkins-x-buildpacks'
  )
;

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

-- Stats
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
