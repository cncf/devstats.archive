# `gha_events_commits_file` table

- This table holds commit's files connected with GitHub event additional data.
- It uses `gha_skip_commits` table, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md) as an input.
- Events commits files are generated using [util_sql/create_events_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/create_events_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L566-L592).
- It adds new event's commit's files every hour, creating full files paths that include repository name.
- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all commits' files connected with events data.
- It contains about 1.2M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L979-L998).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L225-L235).
- Its primary key is `(sha, event_id, path)`.

# Columns

- `sha`: commit SHA.
- `event_id`: GitHub event ID that refers to this commit file.
- `path`: full path generated as repo's path (like org/repo) and file's path (like dir/file.ext) --> `org/repo/dir/file.ext`.
- `size`: file size at commit's date.
- `dt`: commit's date.
- `repo_group`: repository group - this is updated every hour based on commit's file's repository's repo group and (possibly for Kubernetes) file level granularity repository groups definitions, see [repo groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md).
- `dup_repo_id`:  GitHub repository ID of given commit's file
- `dup_repo_name`: GitHub repository name, please note that repo name can change in time, but repo ID remains the same. Full path can contain historical repo names.
- `dup_type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `dup_created_at`: GitHub event's creation date.
- Columns starting with `dup_` are copied from `gha_events` table entry, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
