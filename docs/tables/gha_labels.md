# `gha_labels` table

- This table holds GitHub labels.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Labels are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1277-L1282).
- In pre-2015 events labels [have no ID](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1272).
- For any label found in JSON payload we're searching for existing label using name & color. If label is not found, it receives [artificial negative ID](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L282), see [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L263-L285).
- It contains about 2.6k records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L515-L531).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L391-L396).
- Its primary key is `(id)`.
- Values from this table are sometimes duplicated in other tables (to speedup processing) as `dup_label_name`, `dup_label_id` or `label_id`.

# Columns

- `id`: GitHub label ID.
- `name`: GitHub label name.
- `color`: Color as 6 hex digits: RRGGBB, R,G,B from {0, 1, 2, .., 9, a, b, c, d, f}.
- `is_default`: Not used, can be null. True - label is default, False/null - label is not default.
