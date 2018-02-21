# `gha_actors` table

- This table holds all GitHub actors (actor can be contributor, forker, commenter etc.)
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Actors are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L20-L31).
- Actors imported from GHA have no name (only id and login), name can be updated by import affiliations tool.
- They can also be added by import affiliation tool [here](https://github.com/cncf/devstats/blob/master/cmd/import_affs/import_affs.go#L101-L108) or updated [here](https://github.com/cncf/devstats/blob/master/cmd/import_affs/import_affs.go#L199-L201).
- It contains about 77K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L60-L76).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L41-L45).
- Its primary key is `id`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_actor_id`, `dup_actor_login`.

# Columns

- `id`: actor ID, if > 0 then it comes from GitHub, if < 0 - created artificially (pre-2015 GitHub actors had no ID).
- `login`: actor's GitHub login (you can access profile via `https://github.com/login`).
- `name`: actors name, there is no `name` defined in GitHub archives JSONs, if this value is set - it means it was updated by the affiliations import tool (or entire actor entry comes from affiliations import tool).
