# Continuous deployment (CD) using Travis

- Every commit triggers Travis CI tests.
- Once travis finishes tests, it fires Webhook as defined in [.travis.yml](https://github.com/cncf/devstats/blob/master/.travis.yml).
- By default it make HTTP POST to the following addresses: https://cncftest.io:2982/hook and https://devstats.web.io:2982/hook
- There is a tool `cmd/webhook/webhook` that listens to those webhook events.
- By default we use https protocol. To do so we need Apache server to proxy https requests on 2982 port, into http requests to localhost:1982 (webhook tool only understands http).
- To configure Apache we use those config files [ports.conf](https://github.com/cncf/devstats/blob/master/apache/ports.conf) and [000-default-le-ssl.conf](https://github.com/cncf/devstats/blob/master/apache/sites-available/000-default-le-ssl.conf).
- You can change `webhook`'s port via `GHA2DB_WHPORT` environment variable (default is 1982) and `webhook`'s root via `GHA2DB_WHROOT` (default is `hook`). Please see [usage](https://github.com/cncf/devstats/blob/master/USAGE.md) for details.
- By default `webhook` tool verifies payloads to determine if they are original Travis CI payloads. To enable testing locally You can start tool via `GOPATH=/path GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS=... GHA2DB_SKIP_VERIFY_PAYLOAD=1 ./webhook` or use ready script `webhook.sh` and then use `./test_webhook.sh` script for testing.
- You need to set both `GOPATH` and `GHA2DB_PROJECT_ROOT` because cron job environment have no environment variables set at all, You also have to set `PG_PASS` (this is to allow `webhook` to log into database in addition to `/tmp/gha2db_*` files).
- Webook must be run via cron job (it can be called every 5 minutes because every next instance will either start or do nothing due to port being used by previous instance).
- See [crontab.entry](https://github.com/cncf/devstats/blob/master/crontab.entry) for details, you need to tweak it a little and install via `crontab -e`.
- You can set `GHA2DB_DEPLOY_BRANCHES`, default "master", comma separated list, uto set which branches should be deployed.
- You can set `GHA2DB_DEPLOY_STATUSES`, default "Passed,Fixed", comma separated list, to set which branches should be deployed.
- You can set `GHA2DB_DEPLOY_RESULTS`, default "0", comma separated list, to set which Travis CI results should be deployed.
- You can set `GHA2DB_DEPLOY_TYPES`, default "push", comma separated list, to set which event types should be deployed.
- You *MUST* set `GHA2DB_PROJECT_ROOT=/path/to/repo` for webhook tool, this is needed to decide where to run `make install` on successful build.
- You should list only production branch via `GHA2DB_DEPLOY_BRANCHES=production` for production server, and You can list any number of branches for test servers: devstats.web.io is a production server, while cncftest.io is a test server.
- If You changed `webhook` tool and deploy was successful - you need to kill old running instance via `killall webhook` then wait for cron to fire it again, to se if it works use `ps -aux | grep webhook`.
