# `gha_payloads` table

- This is the main GHA (GitHub archives), every GitHub event contain payload. This event ID is this table's primary key `event_id`.
- This table serves to connect various payload structures for different event types - like connect Issue with Comment for Issue Comment event etc.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Payloads are created during standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L839) or [here (current format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1105).
- Old (pre-20150 GitHub events have no ID, it is generated artificially [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1355), old format ID are < 0.
- It contains about 1.8M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L188-L236).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L504-L529).
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating events of type `ArtificialEvent` when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- Artificial event's payloads are created too.
- Its primary key is GitHub event ID `event_id`.
- Each payload have single (1:1) entry in [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) table.

# Columns

Most important columns are (most of them are only filled for a specific event type, so most can be null - with the exception of `event_id` and those starting with `dup_` which are copied from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md), [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) and [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)):
- `event_id`: GitHub event ID.
- `dup_type`: GitHub event type, can be: PullRequestReviewEvent, PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `head`: HEAD branch SHA.
- `action`: Action type, defined for some event types, can be null or `created`, `published`, `labeled`, `closed`, `opened`, `started`, `reopened`, `added`.
- `issue_id`: Issue ID (for Issue related events), see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `pull_request_id`: Pull Request ID (for PR related events), see [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md).
- `comment_id`: Comment ID (for comment related events), see [gha_comments](https://github.com/cncf/devstats/blob/master/docs/tables/gha_comments.md).
- `number`: Issue number (only for Issues related event types) this is an unique number within single repository.
- `forkee_id`: Forkee ID (not used in any dashbord yet, so no docs yet) - `gha_forkee` table, see [structure.go](https://github.com/cncf/devstats/blob/master/structure.go).
- `release_id`: Release ID (not used in any dashbord yet, so no docs yet) - `gha_releases` table, see [structure.go](https://github.com/cncf/devstats/blob/master/structure.go).
- `commit`: Commit's SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `dup_actor_id`: GitHub actor ID (actor who created this event).
- `dup_actor_login`: Duplicated GitHub actor login (from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table).
- `dup_repo_id`: GitHub repository ID.
- `dup_repo_name`: Duplicated GitHub repository name (note that repository name can change in time, but repository ID remains the same, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table).
- `dup_created_at`: Event creation date.
