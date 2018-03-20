# Testing
1. To execute tests that don't require database, just run `make test`, do not set any environment variables for them, one of tests is to check default environment!
2. For tests that require database you will have to set environment variables to enable DB connection, to do it:
- See [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md) for variables starting with `PG_` and `IDB_`.
- ALWAYS set `PG_DB` & `IFB_DB` - default values are "gha" for both database. They cannot be used as test databases, `make dbtest` will refuse to run when Postgres and/or Influx DB is not set (or set to "gha").
- Test cases are defined in `tests.yaml` file.
- Run tests like this: `GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_DB=dbtest IDB_PASS=idbpwd PG_DB=dbtest PG_PASS=pgpwd make dbtest`.
- Or use script shortcut: `GHA2DB_PROJECT=kubernetes PG_PASS=pwd IDB_HOST="localhost" IDB_PASS=pwd ./dbtest.sh`.
- To test only selected SQL metric(s): `GHA2DB_PROJECT=kubernetes PG_PASS=... PG_DB=dbtest TEST_METRICS='new_contributors,episodic_contributors' go test metrics_test.go
- To test single file that requires database: `GHA2DB_PROJECT=kubernetes PG_PASS=pwd IDB_HOST="localhost" IDB_PASS=pwd go test file_name.go`.
3. To check all sources using multiple go tools (like fmt, lint, imports, vet, goconst, usedexports), run `make check`.
4. To check Travis CI payloads use `PG_PASS=pwd IDB_PASS=pwd IDB_HOST=localhost IDB_PASS_SRC=pwd IGET=1 GET=1 ./webhook.sh` and then `./test_webhook.sh`.
5. Continuous deployment instructions are [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
