# Usage

# Devstats image

- Use `./docker/docker_build.sh` to build `devstats` docker image.
- Use `./docker/docker_bash.sh` to bash into `devstats` docker container.
- Use `./docker/docker_publish.sh` to publish `devstats` image to the dockerhub.
- Use `./docker/docker_remove.sh` to remove `devstats` docker image.

# Postgres and deployment

- Use `./docker/docker_psql.sh` to start dockerized Postgres:10 instance.
- Use `./docker/docker_psql_into_logs_db.sh` to connect to dockerized postgres host post 65432 -> container port 5432.
- Use `PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... ./docker/docker_deploy.sh` to deploy single project (buildpacks) into the dockerized postgres.
- It will use `./docker/docker_deploy_all.sh` script which currently uses `SKIPGRAFANA=1`, `GHA2DB_GHAPISKIP=1` and `ONLY=buildpacks; export ONLY`.
- Use `PG_PASS=... ./docker/docker_display_logs.sh` to see deployment logs.
- Use `PG_PASS=.., ./docker/docker_health.sh` to do a health check (after succesfull deployment). It will display number of texts in the buildpacks database.

docker_display_logs.sh  docker_health.sh
