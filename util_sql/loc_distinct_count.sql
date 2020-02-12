select 
  distinct rl.lang_name as "Language",
  --count(distinct r.name) as "Repositories (names)",
  count(distinct r.alias) as "Repositories",
  --sum(rl.lang_loc) as "LOC (non distinct)",
  -- sum(distinct rl.lang_loc) as "LOC distinct"
  sum(rl.lang_loc) as "LOC"
  --r.id as "Repository ID",
  --r.name as "Repository name",
  --r.alias as "Repository alias",
  --rl.lang_loc as "LOC"
from
  gha_repos r,
  gha_repos_langs rl
where
  r.name = rl.repo_name
  and rl.lang_name is not null and rl.lang_name not in ('', 'unknown')
  and (r.name, r.id) = (
    select i.name,
      i.id
    from
      gha_repos i
    where
      i.alias = r.alias
      and i.name like '%_/_%'
      and i.name not like '%/%/%'
    limit 1
  )
group by
  rl.lang_name
order by
  "LOC" desc
