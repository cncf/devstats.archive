# Usage

# Devstats image

- Use `./docker/docker_build.sh` to build `devstats` docker image.
- Use `./docker/docker_bash.sh` to bash into `devstats` docker container.
- Use `./docker/docker_publish.sh` to publish `devstats` image to the dockerhub.
- Use `./docker/docker_remove.sh` to remove `devstats` docker image.
- Use `./docker/docker_cleanup.sh` to remove all containers and do `docker system prune`.
- Use `./docker/docker_remove_mapped_data.sh` to remove all data from directories shared between the host and containers.

# ElasticSearch

- Use `./docker/docker_es.sh` to start dockerized ElasticSearch 6.5.1 instance.
- Use `./docker/docker_es_bash.sh` to bash into the ElasticSearch container.
- Use `./docker/docker_es_indexes.sh` to see ES indexes.
- Use `./docker/docker_es_types.sh index` to see given index types.
- Use `./docker/docker_es_values.sh index` to see given index types.
- Use `./docker/docker_es_dump.sh indexname filename` to dump ES index into a file.
- Use `./docker/docker_es_restore.sh indexname filename` to restore ES index from a file.
- Use `./docker/docker_es_query.sh index type query` to query ES instance (allows quick lucene queries).
- Use `./docker/docker_es_search.sh index type query` to search ES instance (allows full query search JSON syntax).
- Use `./docker/docker_es_logs.sh` to see ES logs.
- Use `./docker/docker_es_health.sh` to do a health check (after succesfull deployment). It will display some inmdex structures and do some basic queries.
- Use `./docker/docker_remove_es.sh` to remove dockerized postgres instance.
- Use `./docker/docker_es_wait.sh` to wait for the ES docker container become ready.


# Postgres and deployment

- Use `PG_PASS=... ./docker/docker_psql.sh` to start dockerized postgres:11 instance.
- Use `PG_PASS=... ./docker/docker_psql_bash.sh` to bash into the Postgres container.
- To deploy from the host use `` GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauth`" PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... ./docker/docker_deploy_from_host.sh ``.
- To deploy from the container use `` GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauth`" PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... ./docker/docker_deploy_from_container.sh ``.
- It will deploy few Linux Foundation Networking projects into the dockerized postgres.
- It will use `./docker/docker_deploy_all.sh` script which currently uses `SKIPGRAFANA=1` and `NOBACKUP=1`.
- Use `PG_PASS=... ./docker/docker_psql_into_logs_db.sh` to connect to dockerized postgres host post 65432 -> container port 5432.
- Use `PG_PASS=... ./docker/docker_display_logs.sh` to see deployment logs.
- Use `PG_PASS=... ./docker/docker_health.sh` to do a health check (after succesfull deployment). It will display number of texts in the database.
- Use `./docker/docker_remove_psql.sh` to remove dockerized postgres instance.
- Use `PG_PASS=... ./docker/docker_psql_wait.sh` to wait for the postgres docker container become ready.


# Devstats hourly sync

- Use `` GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauth`" PG_PASS=... ./docker/docker_devstats.sh `` to do devstats sync. This should be run hourly, ideally when new GHA files are available which is about every hour:08.


# Minimal devstats image

- If you only want to deploy from host, you can use `Dockerfile.minimal` and `Makefile.minimal` to build minimal devstats image. It will skip all tools needed to bootstrap database and deploy projects.


# DockerHub

- Devstats image can be pulled from the [docker hub](https://hub.docker.com/r/lukaszgryglicki/devstats/).


# One command test all

- Use `PASS=... DEPLOY_FROM=host|container ./docker/docker_test_all.sh` to test full deployment from either the host or the container. It will try to use `/etc/github/oauth` as a GitHub OAuth token (if file is present, otherwise it will use public mode - very restricted).
- Or specify GitHub OAuth token manually `GHA2DB_GITHUB_OAUTH=... PASS=... DEPLOY_FROM=host|container ./docker/docker_test_all.sh` to test full deployment from either the host or the container.
- Use `DEPLOY_FROM=host` only on the machine that already has `golang` configured, has all development tools and go static analysis tools, follow `INSTALL_UBUNTU18.md` for details. For a clean OS installs use `DEPLOY_FROM=container`.
- Final command on a fresh system should be `clear; GHA2DB_GITHUB_OAUTH=key PASS=test DEPLOY_FROM=container ./docker/docker_test_all.sh`.
- To use aurora postgres database `clear; GHA2DB_GITHUB_OAUTH=key PASS=test DEPLOY_FROM=container AURORA=1 ./docker/docker_test_all.sh`.


# Setup

- Use `./docker/docker_setup.sh` to bootsrap environment to run `./docker/docker_test_all.sh`.


