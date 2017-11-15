# Contributing to devstats
If You see any error, or if You have suggestion please create [issue and/or PR](https://github.com/cncf/devstats).

# Coding standards
- Please follow coding standards required for Go language.
- This is checked during the `make` step which calls the following static analysis/lint tools: `fmt lint imports vet const usedexports`.
- When adding new functionality please add test coverage please that will be executed by `make test`.
- If adding new database functionality and/or new metrics, please add new test covergage that will be executed by:
- `GHA2DB_PROJECT=kubernetes IDB_HOST="172.17.0.1" PG_PASS='...' IDB_PASS='...' ./dbtest.sh`.
- New metrics test coverage should be added in `metrics_test.go`.

# Testing
Please see [Tests](https://github.com/cncf/devstats/blob/master/TESTING.md)

# Vulnerabilities
Please use GitHub [issues](https://github.com/cncf/devstats/issues) to report any vulnerability found.
