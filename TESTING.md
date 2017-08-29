# Testing
1. To execute tests that don't require database, just run `make test`
2. For tests that require database You will have to set environment variables to enable DB connection, to do it:
- See `USAGE.md` for variables starting with `PG_` and `IDB_`.
- Run tests like this: `IDB_DB=dbtest IDB_PASS=idbpwd PG_DB=dbtest PG_PASS=pgpwd make dbtest`
