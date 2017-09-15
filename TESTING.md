# Testing
1. To execute tests that don't require database, just run `make test`, do not set any environment variables for them, one of tests is to check default environment!
2. For tests that require database You will have to set environment variables to enable DB connection, to do it:
- See [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md) for variables starting with `PG_` and `IDB_`.
- ALWAYS set `PG_DB` & `IFB_DB` - default values are "gha" for both database. They cannot be used as test databases, `make dbtest` will refuse to run when Postgres and/or Influx DB is not set (or set to "gha").
- Run tests like this: `IDB_DB=dbtest IDB_PASS=idbpwd PG_DB=dbtest PG_PASS=pgpwd make dbtest`
3. To check all sources using multiple go tools (like fmt, lint, imports, vet), run `make check`
