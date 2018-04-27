# `gha_repos` table

- This table holds GitHub repositories.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Repos are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L34-L44).
- Repo can change name in time, but repo ID remains the same in this case.
- Repositories have special groupping columns: `alias` and `repo_group`. Alias can be used to group the same repo (different names in time but the same ID) under the same `alias`.
- Usually alias refers to most recent repo name plus eventually some special names for multiple repositories (can be defined per project), but usually all of repos from the same alias has the same `id`.
- See [example](https://github.com/cncf/devstats/blob/master/scripts/prometheus/repo_groups.sql#L1-L20) to see typical repository aliases definition.
- `repo_group` is used in many dashboards to grroup similar repositories under some special name. Repository groups are setup once by `{{project_name}}/setup_repo_groups.sh`.
- For Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L13)). It calls [kubernetes/setup_repo_groups.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_repo_groups.sh)
- This in turn executes SQL script: [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql). Each project can have its own project-specific aliases/repo groups definitions.
- It contains 135 records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L137-L157).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L665-L672).
- Its primary key is `(id, name)`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_repo_id`, `dup_repo_name`.

# Columns

- `id`: GitHub repository ID.
- `name`: GitHub repository name, can change in time, but ID remains the same then.
- `org_id`: GitHub organization ID (can be null) see [gha_orgs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_orgs.md).
- `org_login`: GitHub organization name duplicated from `gha_orgs` table (can be null). This can be organization name or GitHub username.
- `repo_group`: Artificial column, updated by specific per-project scripts.
- `alias`: Artificial column, updated by specific per-project scripts. Usually used to keep the same name for the same repo, for entire repo name change history.
