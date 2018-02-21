# `gha_events` table

- This is the main GHA (GitHub archives) table. It represents single event.
- Each GHA JSON contains single GitHub event, and singe GHA hour archive file and a bunch (about 80k) JSONS (events) that happened this hour (I mean events on all GitHup repos, not only Kubernetes).
- This table holds all GitHub events. Other tables defined as [variable](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md) have `event_id` as a part of their primary key.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Events are created during standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L791-L809) or [here (current format](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1056-L1074).
- Old (pre-20150 GitHub events have no ID, it is generated artificially [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1355), old format ID are < 0.
- For details about pre-2015 and current format check [analysis](https://github.com/cncf/devstats/tree/master/analysis), per-2015 data is prefixed with `old_`, current format is prefixed with `new_`. Example old and new JSONs [here](https://github.com/cncf/devstats/tree/master/jsons).
- It contains about 1.8M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L23-L40).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L205-L216).
- Its primary key is `id`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_type`, `dup_created_at`.

# Columns

- `id`: 
- `event_id`: 
- `assignee_id`: 
- `body`: 
- `closed_at`: 
- `comments`: 
- `created_at`: 
- `locked`: 
- `milestone_id`: 
- `number`: 
- `state`: 
- `title`: 
- `updated_at`: 
- `user_id`: 
- `is_pull_request`: 
- `dup_actor_id`: 
- `dup_actor_login`: 
- `dup_repo_id`: 
- `dup_repo_name`: 
- `dup_type`: 
- `dup_created_at`: 
- `dupn_assignee_login`: 
- `dup_user_login`: 
