#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_CSVOUT="committers_affiliations.csv" runq ./util_sql/committers_affiliations.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"
