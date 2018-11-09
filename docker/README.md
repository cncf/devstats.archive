# Usage

# Devstats image

- Use `./docker/docker_build.sh` to build `devstats` docker image.
- Use `./docker/docker_bash.sh` to bash into `devstats` docker container.
- Use `./docker/docker_publish.sh` to publish `devstats` image to the dockerhub.
- Use `./docker/docker_remove.sh` to remove `devstats` docker image.


# Postgres and deployment

- Use `./docker/docker_psql.sh` to start dockerized Postgres:10 instance.
- To deploy from the host use `PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... ./docker/docker_deploy_from_host.sh`.
- To deploy from the container use `PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... ./docker/docker_deploy_from_container.sh`.
- It will deploy single project (buildpacks) into the dockerized postgres.
- It will use `./docker/docker_deploy_all.sh` script which currently uses `SKIPGRAFANA=1`, `GHA2DB_GHAPISKIP=1` and `ONLY=buildpacks; export ONLY`.
- Use `./docker/docker_psql_into_logs_db.sh` to connect to dockerized postgres host post 65432 -> container port 5432.
- Use `PG_PASS=... ./docker/docker_display_logs.sh` to see deployment logs.
- Use `PG_PASS=... ./docker/docker_health.sh` to do a health check (after succesfull deployment). It will display number of texts in the buildpacks database.
- Use `./docker/docker_remove_psql.sh` to remove dockerized postgres instance.


# Devstats hourly sync
- Use `PG_PASS=... ./docker/docker_devstats.sh` to do devstats sync for buildpacks. This should be run hourly, ideally when new GHA files are available which is about every hour:08.


# Minimal devstats image

- If you only want to deploy from host, you can use `Dockerfile.minimal` to build devstats image. It will skip all tools needed to bootstrap database and deploy projects.
