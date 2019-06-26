# `gha_skip_commits` table

- Table is used to store invalid SHAs, to skip processing them again.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- We're listing all yet unprocessed commits using [util_sql/list_unprocessed_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/list_unprocessed_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L468-L495).
- More details about commits processing [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits_files.md).
- Some commits are merge commits (skipped) or have no files modifed, or only refer to files that are marked to skip, or cannot be found etc. Their SHAs are put in this table. This is a part of commits sync that happens every hour.
- Files that are skipped are defined per project with `files_skip_pattern`, see yaml definition [here](https://github.com/cncf/devstats/blob/master/gha.go#L26).
- For Kubernetes it is defined [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L13). Exclude regexp is `(^|/)_?(vendor|Godeps|_workspace)/` - it tries to exclude any work done on external packages. 
- To see code that excludes commit files, search for `filesSkipPattern` [mostly here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L405) and [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L527-L537).
- If commit has no files after filtering excluded ones, its SHA is added to `gha_skip_commits` table.
- This is a special table, not created by any GitHub archive (GHA) event.
- It contains about 264K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1000-L1009).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L681-L683).
- Its primary key is `(sha, reason)`.

# Columns

- `sha`: commit SHA.
- `dt`: date when this commit was marked as skipped.
- `reason`: integer: 1 - error getting commit files or no commit files, 2 - error geting LOC stats.
