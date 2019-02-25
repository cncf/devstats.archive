# Kubernetes deployment

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./k8s/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./k8s/remove_images.sh`. They're not needed locally, only Kubernetes cluster needs them.
- To test sync DevStats image (`devstats-minimal` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats-minimal`.
- To test provisioning DevStats image (`devstats` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats`.
- To bash into a running pod do: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`, where pod name can be for example: `devstats-provision-1550826466080940119`, `devstats-test-1550826466080940119`, `devstats-minimal-test-1550826466080940119`, `devstats-1550826466080940119`.
- To dry-run test provisioning and hourly sync pods against your Kubernetes cluster, run: `AWS_PROFILE=... ./k8s/dryrun_manifest.sh k8s/manifests/*`.

# Run provisioning and hourly sync manually

You can test provisioning (including the first bootstrap) by running the kubernetes pods manually, interactively (with TTY in/out):

- To initialize everything from scratch: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_ADMIN_USER=... PG_PASS=... INIT=1 PG_PASS_RO=... PG_PASS_TEAM=... ./k8s/provision_data.sh`.
- If you already have users (`gha_admin`, `ro_user`, `devstats_team`) and logs database (`devstats`) skip the init part: `AWS_PROFILE=... DOCKER_USER=... PROJ=... PROJDB=... PROJREPO=... ONLY=... GETREPOS=1 GHA2DB_GITHUB_OAUTH="`cat /etc/github/oauths`" ES_PROTO=... ES_HOST=... ES_PORT=... PG_HOST=... PG_PORT=... PG_PASS=... ./k8s/provision_data.sh`.
- XXX: `GETREPOS=1` will no longer be needed when we have persistent volume enabled in K8s deployment.
