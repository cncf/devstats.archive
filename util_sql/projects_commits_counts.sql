select r.repo_group, count(distinct sha) as count from gha_commits c, gha_repos r where c.dup_repo_id = r.id and c.dup_repo_name = r.name group by r.repo_group order by count desc;
