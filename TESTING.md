# Testing

- See [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md) for variables starting with `PG_`.
- Test cases are defined in `tests.yaml` file.
- Run tests like this: `PG_PASS=... make test`.
- To test only selected SQL metric(s): `PG_PASS=... TEST_METRICS='new_contributors,episodic_contributors' make test`.
- If you set `debug: true` in DB test case (in `tests.yaml`), you can see data used for test in `dbtest` database.
- You can then use `` GHA2DB_LOCAL=1 PG_DB=dbtest PG_PASS=... runq metric_file.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{from}} 2017-09-01 {{to}} 2017-10-01 {{n}} 1 ``.
- Continuous deployment instructions are [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
