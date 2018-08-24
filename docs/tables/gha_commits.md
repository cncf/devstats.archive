# `gha_commits` table

- This table contains commits data.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- Commits are created during the standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L910-L926) and [here (current format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1162-L1178).
- Commit contain actor name (not login) as reported by `git commit`, so it can be difficult to map to a real actor (somebody can have non-standard name on a local computer), but we also have a GitHub login of actor who made a `git push` to a GitHub repository.
- Usually the same person makes commit and push, so this maps "good enough" - we can also search for actor name, but only actors imported by affiliations tool have a name, for details see [actors table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md).
- It contains about 209K records as of Feb 2018, 148K distinct commit SHAs. It means that there are about 209/148 = 1.41 events/commit. So about 41% of commits are referenced more than once.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L265-L295).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L159-L171).
- Its primary key is `(sha, event_id)`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_actor_id`, `dup_actor_login`.

# Columns

- `sha`: commits unique SHA.
- `event_id`: GitHub event ID refering to this commit.
- `author_name`: Author name as provided by commiter when doing `git commit`. This is *NOT* a GitHub login.
- `encrypted_email`: Author email encrypted by GitHub, for example `76f8b7dc8ef32a26553fcbdb25b75cb20f767b8e@gmail.com`.
- `message`: Commit message.
- `is_distinct`: boolean true/false.

# Duplicates from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) table

Those columns duplicate value from a GitHub event refering to this column `event_id`.
- `dup_actor_id`: event's actor ID.
- `dup_actor_login`: event's GitHub login (actor who pushed this commit).
- `dup_repo_id`: event's GitHub repository ID.
- `dup_repo_name`: event's GitHub's repository name (note that repository name can change in thime, while repository ID is not changing).
- `dup_type`: event's type like PushEvent, PullRequestEvent, ...
- `dup_created_at`: event's creation date.
