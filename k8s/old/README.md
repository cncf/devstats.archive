# Run provisioning and hourly sync manually

You can test provisioning (including the first bootstrap) by running the kubernetes pods manually, interactively (with TTY in/out):

- To initialize everything from scratch: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_ADMIN_USER=... PG_PASS=... INIT=1 PG_PASS_RO=... PG_PASS_TEAM=... ./k8s/old/provision_data.sh`.
- If you already have users (`gha_admin`, `ro_user`, `devstats_team`) and logs database (`devstats`) skip the init part: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GETREPOS=1 GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_PASS=... ./k8s/old/provision_data.sh`.
- XXX: `GETREPOS=1` will no longer be needed when we have persistent volume enabled in K8s deployment.
- To test hourly sync manually: `AWS_PROFILE=.. DOCKER_USER=... GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" GHA2DB_ES_URL=... PG_HOST=... PG_PORT=... PG_PASS=... GHA2DB_PROJECTS_YAML="k8s/projects.yaml" GHA2DB_PROPAGATE_ONLY_VAR=1 GHA2DB_USE_ES=1 GHA2DB_USE_ES_RAW=1 ONLY=... ./k8s/old/hourly_sync.sh`.

