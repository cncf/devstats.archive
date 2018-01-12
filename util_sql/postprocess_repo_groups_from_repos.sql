-- Finally update repo_group from repository definition (where it is not yet set from files paths)
update
  gha_events_commits_files ecf
set
  repo_group = r.repo_group
from
  gha_repos r
where
  r.name = ecf.dup_repo_name
  and r.repo_group is not null
  and ecf.repo_group is null
;

