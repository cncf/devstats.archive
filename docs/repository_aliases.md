# DevStats repository aliases

- Repository alias is usually defined as the most recent name of a given repository.
- GitHub identifies repositories by `id`. Sometimes repositories are renamed. In those cases we will have multiple repos with the same `id` but different name.
- Usually alias refers to most recent repo name plus eventually some special names for multiple repositories (can be defined per project), but usually all of repos from the same alias has the same `id`.
- See [example](https://github.com/cncf/devstats/blob/master/scripts/prometheus/repo_groups.sql#L1-L20) to see typical repository aliases definition.
- More info about `gha_repos` table [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).
- This is the query that updates repository aliases every hour (most projects use this to keep repository alias pointing to most up-to-date repo name):
```
update
  gha_repos r
set
  alias = coalesce((
    select i.name
    from
      gha_repos i,
      gha_events e
    where
      i.id = r.id
      and e.repo_id = r.id
      and i.name like '%_/_%'
      and i.name not like '%/%/%'
    order by
      e.created_at desc
    limit 1
  ), name)
;
```
