# `gha_texts` table

- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all texts entered by all actors on all Kubernetes repos.
- It contains about 4.6M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1046-L1073).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L726-L735).
- This table is updated every hour via [util_sql/postprocess_texts.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_texts.sql).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_texts` table every hour.
- It adds all new comments, commit messages, issue titles, issue texts, PR titles, PR texts since last hour.
- See documentation for [issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md), [PRs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) and [commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md) tables.
- This SQL script is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L1).
- Default postprocess scripts are defined by [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- Setup scripts is called by main Postgres init script, for kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14).
- This is a part of standard when adding new project, for adding new project please see: [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
- When adding a project to an existing database that contains merge result from multiple projects, you need to manually remove eventual duplicates using: [./devel/remove_db_dups.sh](https://github.com/cncf/devstats/blob/master/devel/remove_db_dups.sh), as suggested by [cmd/merge_dbs/merge_dbs.go](https://github.com/cncf/devstats/blob/master/cmd/merge_dbs/merge_dbs.go#L197).
- Informations about creating project that is a merge of other multiple projects can be found in [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
- Its primary key isn't `event_id`, because it adds both title and body of issues and commits.

# Columns

- `event_id`: GitHub event ID. This ID is artificially generated for pre-2015 events.
- `body`: text, can be very long.
- `created_at`: date of the corresponding GitHub event.
- `actor_id`: actor ID responsible for this text. Refers to [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table.
- `actor_login`: actor GitHub login responsible for this text. Refers to [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table.
- `repo_id`: GitHub repository ID where this text was added. Refers to [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table.
- `repo_name`: GitHub repository name where this text was added. please not that repository names can change in time, but ID remains the same.
- `type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
