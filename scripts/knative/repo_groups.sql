-- Knative
update
  gha_repos
set
  repo_group = 'Knative'
where
  org_login = 'knative'
;


-- Knative Sandbox
update
  gha_repos
set
  repo_group = 'Knative Sandbox'
where
  org_login = 'knative-sandbox'
;
