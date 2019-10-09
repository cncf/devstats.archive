select count(distinct id) as {{what}} from gha_pull_requests where {{what}}_at >= '{{from}}' and merged_at < '{{to}}' and dup_repo_name = '{{repo}}'
