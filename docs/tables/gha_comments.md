# `gha_comments` table

- This is a table that holds GitHub comments state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- It contains issue and PR comments, PR review comments and commit comments.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 138K records (Mar 2018 state). There is usually only one event/comment. In rare cases we have review comments on an exiting comment.
- Its primary key is `(event_id, id)`.

# Columns

Most important columns are:
- `id`: GitHub Comment ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: Comment text.
- `created_at`: Comment creation date.
- `updated_at`: Comment update date. Note that this table holds Comment state in time, comment can be modified, so updated_at will change.
- `user_id`: GitHub user ID who added comment.
- `commit_id`: If this is a commit comment, this contains commit SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `position`: Position in file, can be null.
- `path`: File path if this is a commit comment, can be null.
