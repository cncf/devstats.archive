select
  distinct coalesce(r.repo_group, 'No repo group') as "Repo group",
  r.name as "Repo",
  r.license_name as "License",
  rl.lang_name as "Language",
  rl.lang_loc as "LOC",
  rl.lang_perc as "Language percent"
from
  gha_repos r,
  gha_repos_langs rl
where
  r.name = rl.repo_name
; 
