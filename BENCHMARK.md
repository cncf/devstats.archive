# Benchmarks

Here are results of benchmarks:

We're trying 3 versions:
- Ruby on Postgres.
- Ruby on MySQL.
- Go on Postgres.

On 2 data sets:
- All kubernetes GHA events (orgs `kubernetes`, `kubernetes-incubator` and `kubernetes-client`) on single month `2017-07-01` - `2017-08-01`.
- All GHA events (no org/repo filter) on 2 days `2017-08-01` - `2017-08-03` (Tue and Wed).

Columns:
- `Benchmark` - benchmark name.
- `Events` - number of GHA events created.
- `Real time` - time it took to compute.
- `User time` - time it took to compute on all CPUs (so this is the time it *would* take on single CPU machine).
- `Parrallel` - this is the ratio of `User time` to `Real time` - parallelism factor.

| Benchmark      | Events      | Real time | User time | Parallel |
|----------------|:-----------:|----------:|----------:|---------:|
| K8s go@Psql    | 65851       | 05m5.3s   | 81m44.1s  | 13.9x    |
| K8s Ruby@Psql  | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| K8s Ruby@MySQL | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| All go@Psql    | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| All Ruby@Psql  | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |
| All Ruby@MySQL | xxxxx       | xxxxxxx   | xxxxxxxx  | xxxxx    |

# Results

When processing only Kubernetes events, we still need to download, decompress, parse all JSON and slect only those with specific org.

This is lightning fast in Go, while terribly slow in Ruby.
