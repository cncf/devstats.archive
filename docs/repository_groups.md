# Repository groups

- Most project use 'repository groups' to group data under them.
- It is usually defined on the repository level, which means that for example 3 repositories belong to 'repository group 1', and some 2 others belong to 'repository group 2'.
- They can also be defined on the file level, meaning that some files from some repos can belong to a one repository group, while others belong to the other repository group.
- Only Kubernetes project uses 'file level granularity' repository groups definitions.
- For Kubernetes they are defined in main postgres script: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L13).
- It uses [kubernetes/setup_repo_groups.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_repo_groups.sh).
- It finally executes this SQL script: [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql).
- It defines repository groups for given repository names.
- The file level granularity part is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14).
- This setup postprocessing scripts:
- One is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L5-L6) which adds postprocess script:
- [util_sql/repo_groups_postprocess_script.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script.sql) which finally executes: [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) every hour.
- This SQL updates `gha_events_commits_files` table (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md)) by setting repository group based on file path, for example:
- These [lines](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql#L10-L12) are setting repo group based on full path including repo name, and they set different repo group than defined for `kubernetes/kubernetes` (`Cluster lifecycle` instead of `Kubernetes`).
- These [lines](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql#L23-L34) are setting repo group based on PR review comments on specific files in specific repository (also overriding `Kubernetes` with `Cluster lifecycle`).
- Another is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L7-L8) which adds postprocess script (this is used in all projects, not only K8s):
- [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql) which finally executes: [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql).
```
update
  gha_events_commits_files ecf
set
  repo_group = r.repo_group
from
  gha_repos r
where
  r.name = ecf.dup_repo_name
  and r.repo_group is not null
  and ecf.repo_group is null;
```
- It updates `gha_events_commits_files` table (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md)) setting the same repo group as given file's repository's repo group when file's repoository's repo group is defined and when file's repo group is not yet defined.
- Important part is to update only where commit's file's repo group [is not yet set](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql#L11) and only when commit's file's repository has [repo group set](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql#L10).
- Generally all postprocess scripts that run every hour are defined in the table `gha_postprocess_scripts` (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md)), currently: repo groups, labels, texts, PRs, issues.
- More info about `gha_repos` table [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).

# Other projects
- Non Kubernetes projects are not setting `util_sql/repo_groups_postprocess_script.sql`, for example Prometheus uses [this](https://github.com/cncf/devstats/blob/master/prometheus/setup_scripts.sh). Note missing [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) part.
- It only adds [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql), which executes [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql).
- So it only updates `gha_events_commits_file` table with repository group as defined by commit's file's repository (if defined).
