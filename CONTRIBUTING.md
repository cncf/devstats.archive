# Contributing to gha2db
If You see any error, or if You have suggestion please create [issue and/or PR](https://github.com/cncf/gha2db).

# Coding standards
Please follow coding standards required for Go language.
This is checked during the `make` step which calls the following static analysis/lint tools: `fmt lint imports vet const usedexports`
When adding new functionality please add test coverage please that will be executed by `make test`.
If adding new database functionality and/or new metrics, please add new test covergage that will be executed by `dbtest.sh`.
New metrics test coverage should be added in `metrics_test.go`.

# Testing
Please see [Tests](https://github.com/cncf/gha2db/blob/master/TESTING.md)

# Vulnerabilities
Please use GitHub [issues](https://github.com/cncf/gha2db/issues) to report any vulnerability found.
