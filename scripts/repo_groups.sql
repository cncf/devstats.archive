-- Add repository groups
update gha_repos set repo_group = 'kubernetes' where name in ('kubernetes/kubernetes');

