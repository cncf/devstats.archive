# Kubernetes deployment

- To create DevStats container images use: `DOCKER_USER=... ./k8s/build_images.sh`.
- To drop DevStats container images use: `DOCKER_USER=... ./k8s/remove_images.sh`.
- To test sync DevStats image (`devstats-minimal` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats-minimal`.
- To test provisioning DevStats image (`devstats` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats`.
- To initialize everything from scratch: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_ADMIN_USER=... PG_PASS=... INIT=1 PG_PASS_RO=... PG_PASS_TEAM=... ./k8s/provision_data.sh`.
- If you already have users (`gha_admin`, `ro_user`, `devstats_team`) and logs database (`devstats`) skip the init part: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GETREPOS=1 GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_PASS=... ./k8s/provision_data.sh`.
- XXX: `GETREPOS=1` will no longer be needed when we have persistent volume enabled in K8s deployment.
- To bash into a running pod do: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`, where pod name can be for example: `devstats-provision-1550826466080940119`, `devstats-test-1550826466080940119`, `devstats-minimal-test-1550826466080940119`.
