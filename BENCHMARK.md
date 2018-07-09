# Benchmarks

Please note that those benchmark informations are very old.

Please note that Ruby version was removed. It was slower, and Kubernetes community prefer tools written in Go.

Postgresql was faster than MySQL, so it was only supported in a dropped Ruby version. Go version uses Postgres.

Please not that recently (May 2018) influxDB was removed as well, Postgres is faster even when using it as a time-series database.

Here are historical results of benchmarks Go & Ruby tools:

# gha2db tool benchmarks

We're trying 3 versions:
- Ruby on Postgres.
- Ruby on MySQL.
- Go on Postgres.

On 2 data sets:
- All kubernetes GHA events (orgs `kubernetes`, `kubernetes-incubator`, `kubernetes-client`, `kubernetes-csi`) on single month `2017-07-01` - `2017-08-01`.
- All GHA events (no org/repo filter) on 2 days `2017-08-01` - `2017-08-03` (Tue and Wed).

Columns:
- `Benchmark` - benchmark name.
- `Events` - number of GHA events created. Note that for `All` we have 2.5M events in just 2 days, while for only Kubernetes we have 66K events in a month.
- `Real time` - time it took to compute.
- `User time` - time it took to compute on all CPUs (so this is the time it *would* take on single CPU machine).
- `Parallelism` - this is the ratio of `User time` to `Real time` - parallelism factor.
- `Range` - length of data processed.

And final run for Kubernetes for all `2015-08-06` - `2017-08-26` using Go version of `gha2db`:
- `time PG_PASS='...' PG_DB='test' ./gha2db 2015-08-06 0 2017-08-26 0 'kubernetes,kubernetes-incubator,kubernetes-client,kubernetes-csi'`

Outputs 1200426 GHA events in:
```
real  112m6.604s --> 6726s
user  1718m21.020s --> 103101s
sys 99m43.964s
```

Results Table:

| Benchmark          | Events      | Real time   | User time   | Parallelism | Range    |
|--------------------|:-----------:|------------:|------------:|------------:|---------:|
| K8s Go / Psql      | 65851       | 5m5.3s      | 81m44.1s    | 16.06x      | 1 month  |
| K8s Ruby / Psql    | 65851       | 63m26.817s  | 68m25.120s  | 1.078x      | 1 month  |
| K8s Ruby / MySQL   | 65851       | 66m13.291s  | 69m45.604s  | 1.053x      | 1 month  |
| All Go / Psql      | 2550663     | 6m4.652s    | 37m10.932s  | 6.12x       | 2 days   |
| All Ruby / Psql    | 2550663     | 45m16.238s  | 50m19.916s  | 1.118x      | 2 days   |
| All Ruby / MySQL   | 2550663     | 46m55.949s  | 40m43.796s  | 0.868x      | 2 days   |
| Full K8s Go / Psql | 1200426     | 1h52m6.6s   | 26h38m21s   | 15.33x      | ~2 years |

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
- [JRuby](https://en.wikipedia.org/wiki/JRuby):
```
JRuby has the significant architectural advantage to be able to leverage JVM threads without being constrained by a global interpreter lock (similarly to Rubinius), therefore achieving full parallelism within a process, which Ruby MRI cannot achieve despite leveraging OS threads.
```

Seems like only `JRuby` implementation has real MT processing:
```
Remember that only in JRuby threads are truly parallel (other interpreters implement GIL).
```

So Go will kill Ruby all the time! It is about 10x - 15x faster than Ruby on average.

One word: Go version can import all GitHub archives data (not discarding anything) for all Kubernetes orgs/repos, from the beginning on GitHub 2015-08-06 in about 2 hours!

We can also see that MySQL is very slightly slower that Postgres (but this is just for inserting data, without indexes defined yet).
MySQL is a lot slower on metrics/queries - but this is not checked in this benchmark.

# db2influx/gha2db_sync tools benchmarks

To benchmark db2influx we're just running a command that regenerates all metrics.

This is done automatically by `sync`/`sync.rb` tool that just call `db2influx`/`db2influx.rb` for all time range (when `GHA2DB_RESETIDB` env is set).

This also updates Postgres DB (since last run) using `gha2db`/`gha2db.rb`, so we need to run it once, to make sure no updates are needed.

And then we can start benchmark in another run (it will only recompute all InfluxDB time-series then).

- Go version: `time GHA2DB_RESETIDB=1 PG_PASS='...' IDB_PASS='...' PG_DB=test IDB_DB=test ./sync_go.sh`
```
real  1m28.336s
user  1m54.352s
sys 1m11.860s
```
- Ruby version: `time GHA2DB_PSQL=1 GHA2DB_RESETIDB=1 PG_PASS='...' IDB_PASS='...' PG_DB=test IDB_DB=test ./sync_ruby.sh`
```
real  1m46.342s
user  0m51.488s
sys 0m27.408s
```

| Benchmark           | Real time   | User time   | Parallelism | Range    |
|---------------------|------------:|------------:|------------:|---------:|
| All InfluxDB / Go   | 1m28.336s   | 1m54.352s   | 1.29x       | ~2 years |
| All InfluxDB / Ruby | 1m46.342s   | 0m51.488s   | 0.484x      | ~2 years |

We can see that this task is dominated by query Postgres time, so it is less important which programming language is used to do queries.

We can see that Ruby is very slightly slower.

Plase note that this regenerates ALL InfluxDB data for 2 years and is < 2 minutes.

Generating index takes < 3 minutes.

In a typical case it will only add new time-series since last run + eventually process single new GHA hour (since last run). It usually takes less than minute in both languages.

