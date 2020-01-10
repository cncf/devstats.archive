update
  gha_repos
set
  alias = null,
  repo_group = null
where
  name not like '%_/_%'
  or name like '%/%/%'
;
