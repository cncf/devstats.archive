#!/bin/sh
# Commits for 2016-10-01 - 2017-10-01:
PG_PASS=Admin123_# PG_DB=cloudfoundry ./runq metrics/cloudfoundry_commits.sql {{from}} 2016-10-01 {{to}} 2017-10-01
# PRs + Issues for 2016-10-01 - 2017-10-01:
PG_PASS=Admin123_# PG_DB=cloudfoundry ./runq metrics/cloudfoundry_prs_and_issues.sql {{from}} 2016-10-01 {{to}} 2017-10-01
