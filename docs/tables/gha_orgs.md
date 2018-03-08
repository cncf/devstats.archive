# `gha_orgs` table

- This table holds GitHub organizations.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Orgs are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L47-L60).
- Org name can change name in time (probably?), but organization ID remains the same in this case.
- It contains 6 records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L171-L181).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L472-L475).
- Its primary key is `id`.

# Columns

- `id`: GitHub organization ID.
- `login`: GitHub organization login: it can be organization name (like `kubernetes`) or GitHub user name.
