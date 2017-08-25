Here are results of benchmarsk.

We're trying 3 versions:
- Ruby on Postgres
- Ruby on MySQL
- Go on Postgres

On 2 data sets:
- All kubernetes GHA activity (orgs kubernetes, kubernetes-incubator, kubernetes-client) on one month 2017-07-01 - 2017-08-01
- All GHA (no org/repo filter) on 2 days 2017-08-01 - 2017-08-03 (Tue and Wed)

| Benchmark      | Events      | Real Time | User Time | Parallel |
|----------------|:-----------:|----------:|----------:|---------:|
| K8s go@Psql    | 65851       | 05m5.3s   | 81m44.1s  | 13.9x    |
| K8s Ruby@Psql  | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| K8s Ruby@MySQL | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| All go@Psql    | 65851       | 05m5.3s   | 81m44.1s  | 13.9x    |
| All Ruby@Psql  | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| All Ruby@MySQL | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
