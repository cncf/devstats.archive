# `gha_reviews` table

- This is a table that holds GitHub PR reviews state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- It contains issue and PR review comments, if review type is `commented` then review body is empty and that review's comment body is in `gha_comments` table. It has review body for other review types like: approved, rejected, dismissed, etc.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- Its primary key is `(event_id, id)`.

# Columns

Most important columns are:
- `id`: GitHub Review ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `user_id`: GitHub user ID who added review.
- `commit_id`: commit SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `body`: Review text (`null` for review type `commented`).
- `state`: Review's state: commented, approved, changes_requested, rejected, dismissed, etc.
- `submitted_at`: Review's submit date.
- `author_association`: Reviews's author's associations, for example `member`.
