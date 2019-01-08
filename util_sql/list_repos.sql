select distinct '{{project}}' as project, repo_group, name as repo_name from gha_repos order by repo_group, name;
