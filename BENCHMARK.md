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
- `Parallelism` - this is the ratio of `User time` to `Real time` - parallelism factor.
- `Sys time` - time spent is system calls.

| Benchmark         | Events      | Real time   | User time   | Parallelism | Sys time    | Sys percent  |
|-------------------|:-----------:|------------:|------------:|------------:|------------:|-------------:|
| K8s Go / Psql     | 65851       | 05m5.3s     | 81m44.1s    | 16.06x      | 3m21.304s   | 65.9%        |
| K8s Ruby / Psql   | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |             |              |
| K8s Ruby / MySQL  | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |             |              |
| All Go / Psql     | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |             |              |
| All Ruby / Psql   | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |             |              |
| All Ruby / MySQL  | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |             |              |

# Results

When processing only Kubernetes events, we still need to download, decompress, parse all JSON and slect only those with specific org.

This is lightning fast in Go, while terribly slow in Ruby.
