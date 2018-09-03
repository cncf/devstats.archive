# Conntributors repors

Make sure to apply Format -> Number -> Plain text to all data.

- Use `PG_PASS=... ./util_sh/contributors_and_emails.sh` - it will generate `contributors_and_emails.csv` file, put it on the [first sheet here](https://docs.google.com/spreadsheets/d/1bYL4PHTVfqpByhksNhixegm68aiHZLCokHLX-OYVLHw/edit#gid=468674562).
- Use `PG_PASS=... ./util_sh/contributing_actors.sh` - it will generate `contributing_actors.csv` file, put it on the [second sheet here](https://docs.google.com/spreadsheets/d/1bYL4PHTVfqpByhksNhixegm68aiHZLCokHLX-OYVLHw/edit#gid=1690662570).
- Use `PG_PASS=... ./util_sh/contributing_actors_data.sh` - it will generate `contributing_actors_data.csv` file, put it on the [third sheet here](https://docs.google.com/spreadsheets/d/1bYL4PHTVfqpByhksNhixegm68aiHZLCokHLX-OYVLHw/edit#gid=0).
- Use `PG_PASS=... PG_DB=gha ./runq util_sql/number_of_contributing_actors.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"` to get the number of K8s contributors.
- Use `PG_PASS=... PG_DB=allprj ./runq util_sql/number_of_contributing_actors.sql {{exclude_bots}} "`cat util_sql/exclude_bots.sql`"` to get the number of all CNCF contributors.
- Use `ONLY="prometheus opentracing fluentd linkerd grpc coredns containerd rkt cni envoy jaeger notary tuf rook vitess nats opa spiffe spire opencontainers cloudevents telepresence helm harbor openmetrics" ./util_sh/unique_contributors.sh` to get the number of non-k8s contributors.
- Use `./util_sh/contributors.sh dbname` to get the number of contributors in a given `dbname`.

You can run it from the SSH bastion or locally (assuming cncftest.io has whitelisted your local IP). You can also run it from cncftest.io and download CSVs to your computer to put them in google sheet.
