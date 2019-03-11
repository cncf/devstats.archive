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
  repo_group = 'Spinnaker',
  alias = 'Spinnaker'
where
  org_login in ('spinnaker')
;

-- Tekton
update
  gha_repos
set
  repo_group = 'Tekton',
  alias = 'Tekton'
where
  org_login in ('knative', 'tektoncd')
;

-- Jenkins
update
  gha_repos
set
  repo_group = 'Jenkins',
  alias = 'Jenkins'
where
  org_login in ('jenkinsci')
;

-- Jenkins X
update
  gha_repos
set
  repo_group = 'Jenkins X',
  alias = 'Jenkins X'
where
  org_login in ('jenkins-x')
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
