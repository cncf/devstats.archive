# Benchmarks

Here are results of benchmarks:

# gha2db tool benchmarks

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

Table:

| Benchmark         | Events      | Real time   | User time   | Parallelism |
|-------------------|:-----------:|------------:|------------:|------------:|
| K8s Go / Psql     | 65851       | 5m5.3s      | 81m44.1s    | 16.06x      |
| K8s Ruby / Psql   | 65851       | 63m26.817s  | 68m25.120s  | 1.078x      |
| K8s Ruby / MySQL  | xxxxx       | xxxxxxx     | xxxxxxxx    | xxxxx       |
| All Go / Psql     | 2550663     | 6m4.652s    | 37m10.932s  | 6.12x       |
| All Ruby / Psql   | 2550663     | 45m16.238s  | 50m19.916s  | 1.118x      |
| All Ruby / MySQL  | 2550663     | 46m55.949s  | 40m43.796s  | 0.868x      |

# Results

When processing only Kubernetes events, we still need to download, decompress, parse all JSON and select only those with specific org.

This is lightning fast in Go, while terribly slow in Ruby.

Ruby is not really multi-threaded (Ruby MRI), it uses GIL, and essentially it is just single threaded.

We can see max parallelism ratio about 1.11x which mean that even with 48 CPU cores, current Ruby implementation can make use of 1.11 cores.

Links:
- [Ruby threads not really use multiple CPUs](https://stackoverflow.com/questions/56087/does-ruby-have-real-multithreading)
- `For true concurrency having more then 2 cores or 2 processors is required - but it may not work if implementation is single-threaded (such as the MRI).`:
- [Ruby threads in parallel](https://stackoverflow.com/questions/2428140/how-do-i-run-two-threads-in-ruby-at-the-same-time)
- [Ruby interpreter GIL](https://en.wikipedia.org/wiki/Global_interpreter_lock)

Seems like only `JRuby` implementation has real MT processing:
```
Remember that only in JRuby threads are truly parallel (other interpreters implement GIL).
```

So Go will kill Ruby all the time!

We can also see that MySQL is very slightly slower that Postgres (but this is just for inserting data, without indexes defined yet).
MySQL is a lot slower on metrics/queries - but this is not checked in this benchmark.

# db2influx tool benchmarks

WIP

