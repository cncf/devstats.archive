-- Clear current repo groups (taken from merge of all other projects)
-- This script is executed every hour

update
  gha_repos
set
  repo_group = null,
  alias = null
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
