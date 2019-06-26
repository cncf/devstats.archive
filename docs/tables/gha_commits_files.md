# `gha_commits_files` table

- This table holds commit's files (added, removed, modified etc.)
- We're listing all yet unprocessed commits using [util_sql/list_unprocessed_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/list_unprocessed_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L468-L495).
- Commit's files are created by `git` datasource using [git_files.sh](https://github.com/cncf/devstats/blob/master/git/git_files.sh) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L356-L441).
- This generates data for this table.
- Some commits has no files modifed, they're marked as `skip commits` and their SHAs are put in `gha_skip_commits` table, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md).
- It adds new commit's files every hour by running [get_repos tool](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go).
- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all commits' files.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- It contains about 534K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L965-L978).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L180-L185).
- Its primary key is `(sha, path)`.

# Columns

- `sha`: commit SHA.
- `path`: file path, it doesn't include repo name, so can be something like `dir/file.ext`.
- `ext`: file extension: created from `path` in the following way: `ext = regexp_replace(lower(path), '^.*\.', '')`.
- `size`: file size at commit's date.
- `dt`: commit's date.
