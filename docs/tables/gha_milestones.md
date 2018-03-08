# `gha_milestones` table

- This is a table that holds GitHub milestone state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 265K records but only 351 distinct milestone IDs (Mar 2018 state) - this means that there are about 750 events per milestone on average.
- Its primary key is `(event_id, id)`.

# Columns

Most important columns are:
- `id`: GitHub milestone ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `description`: milestone description.
- `created_at`: Milestone creation date.
- `closed_at`: Milestone close date. Note that this table holds milestone state in time, so for some event this date will be null, for some other it will be set.
- `due_at`: Milestone due date. Note that this table holds milestone state in time, so  this date can change in time (for example when milestone due date is moved to next month etc.).
- `number`: Milestone number.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `title`: Milestone title.
- `creator_id`: GitHub user ID who created this milestone.
- `closed_issues`: number of issues closed for this milestone at given point of time `event_id`.
- `open_issues`: number of open issues for this milestone at given point of time `event_id`.
