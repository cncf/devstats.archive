#!/bin/bash
REPO="kubernetes/kubernetes" MILESTONE="v1.12" ISSUES="66257,88888" GHA2DB_LOCAL=1 GHA2DB_SKIPPDB=1 GHA2DB_RECENT_RANGE="1 hour" GHA2DB_RECENT_REPOS_RANGE="3 hours" PG_DB=gha dlv debug devstats/cmd/ghapi2db
