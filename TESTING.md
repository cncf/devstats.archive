# Testing
1. To execute tests that don't require database, just run `make test`, do not set any environment variables for them, one of tests is to check default environment!
2. For tests that require database you will have to set environment variables to enable DB connection, to do it:
- See [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md) for variables starting with `PG_`.
- ALWAYS set `PG_DB` - default value is "gha". It cannot be used as test database, `make dbtest` will refuse to run when Postgres DB is not set (or set to "gha").
- Test cases are defined in `tests.yaml` file.
- Run tests like this: `PG_PASS=... GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes PG_DB=dbtest make dbtest`.
- Or use script shortcut: `PG_PASS=... GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes ./dbtest.sh`.
- To test only selected SQL metric(s): `PG_PASS=... GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes PG_DB=dbtest TEST_METRICS='new_contributors,episodic_contributors' go test metrics_test.go`.
- To test single file that requires database: `PG_PASS=... GHA2DB_LOCAL=1 GHA2DB_PROJECT=kubernetes PG_DB=dbtest go test file_name.go`.
- If you set `debug: true` in DB test case, you can see data used for test in `dbtest` database.
- You can then use `` GHA2DB_LOCAL=1 PG_DB=dbtest PG_PASS=... ./runq metric_file.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`" {{from}} 2017-09-01 {{to}} 2017-10-01 {{n}} 1 ``.
3. To check all sources using multiple go tools (like fmt, lint, imports, vet, goconst, usedexports), run `make check`.
4. To check Travis CI payloads use `PG_PASS=pwd GET=1 ./webhook.sh` and then `./test_webhook.sh`.
5. Continuous deployment instructions are [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
