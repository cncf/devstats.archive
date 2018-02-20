# `gha_texts` table

- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all texts entered by all actors on all Kubernetes repos.
- It contains about 4.6M records as of Feb 2018.
- It is created here: [istructure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1046-L1073).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L726-L735).
- This table is updated every hour via [util_sql/postprocess_texts.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_texts.sql).
- It adds all new comments, commit messages, issue titles, issue texts, PR titles, PR texts since last hour.
- Its primary key isn't `event_id`, because it adds both title and body of issues and commits.
- This SQL script is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql).
- Default postprocess scripts are defined by [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh). This is `{{projectname}}/setup_scripts.sh` for other projects.
- Setup scripts is called by main Postgres init script, for kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh).
- This is a part of standard when adding new project, for adding new project please see: [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
- When adding a project to an existing database that contains merge result from multiple projects, you need to manually remove eventual duplicates using: [./devel/remove_db_dups.sh](https://github.com/cncf/devstats/blob/master/devel/remove_db_dups.sh), as suggested by [cmd/merge_pdbs/merge_pdbs.go](https://github.com/cncf/devstats/blob/master/cmd/merge_pdbs/merge_pdbs.go#L197).
- Informations about creating project that is a merge of othe rmultiple projects can be found in [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
