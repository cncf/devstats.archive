# `gha_events_commits_files` table

- This table holds commit's files connected with GitHub event additional data.
- It uses `gha_skip_commits` table, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md) as an input.
- Events commits files are generated using [util_sql/create_events_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/create_events_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L566-L592).
- It adds new event's commit's files every hour, creating full files paths that include repository name.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L6-L8). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) is scheduled to run every hour by: [util_sql/repo_groups_postprocess_script.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script.sql).
- SQL script [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql) is scheduled to run every hour by: [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql).
- Those scripts first try to update commit event file's repository group first using file level granularity (1st script) and then fall back to repo level granularity (2nd script).
- They are called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all commits' files connected with events data.
- It contains about 1.2M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L979-L998).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L225-L235).
- Its primary key is `(sha, event_id, path)`.

# Columns

- `sha`: commit SHA.
- `event_id`: GitHub event ID that refers to this commit file.
- `path`: full path generated as repo's path (like org/repo) and file's path (like dir/file.ext) --> `org/repo/dir/file.ext`.
- `ext`: file extension: created from `path` in the following way: `ext = regexp_replace(lower(path), '^.*\.', '')`.
- `size`: file size at commit's date.
- `dt`: commit's date.
- `repo_group`: repository group - this is updated every hour based on commit's file's repository's repo group and (possibly for Kubernetes) file level granularity repository groups definitions, see [repo groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md).
- `dup_repo_id`:  GitHub repository ID of given commit's file
- `dup_repo_name`: GitHub repository name, please note that repo name can change in time, but repo ID remains the same. Full path can contain historical repo names.
- `dup_type`: GitHub event type, can be: PullRequestReviewEvent, PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `dup_created_at`: GitHub event's creation date.
- Columns starting with `dup_` are copied from `gha_events` table entry, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
