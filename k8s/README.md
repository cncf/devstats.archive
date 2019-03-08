# Create and test images

Create and remove docker images:

- To create DevStats docker container images and publish them, use: `DOCKER_USER=... ./k8s/build_images.sh`.
- To drop local DevStats docker container images use: `DOCKER_USER=... ./k8s/remove_images.sh`. They're not needed locally, only Kubernetes cluster needs them.

Testing images (this will not mount PVs and will not propagate secrets):

- To test sync DevStats image (`devstats-minimal` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats-minimal`.
- To test provisioning DevStats image (`devstats` container): `AWS_PROFILE=... DOCKER_USER=... ./k8s/test_image.sh devstats`.

You can also run shell inside the running container:

- To bash into a running pod do: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`, where pod name can be for example: `devstats-provision-1550826466080940119`, `devstats-test-1550826466080940119`, `devstats-minimal-test-1550826466080940119`, `devstats-1550826466080940119`.


# Secrets

Secret data is not checked-in into the repository. For each file in `k8s/secrets/*.secret.example` you need to create your own `k8s/secrets/*.secret` and propagate into your cluser.

Once all those files are created, use `./k8s/create_secrets.sh` script to propagate them into you Kubernetes cluster.

Please note that `vi` automatically adds new line to all text files, to remove it run `truncate -s -1` on a saved file.


# Test pods before actually running them

This is optional (it starts real containers with their command replaced with the shell and then you can use `./k8s/pod_shell.sh` to shell into them and run their actual command manually):

- To dry-run manifests against your Kubernetes cluster, run: `AWS_PROFILE=... ./k8s/dryrun_manifest.sh ./k8s/manifests/*.yaml ./k8s/other_manifests/*.yaml`.
- Use `AWS_PROFILE=... ./k8s/apply_manifest.sh ./k8s/other_manifests/test-secrets.yaml` to create pod running bash with all sectets passed and PVs mounted. Kubernetes will output pod name, something like: `devstats-test-1551099357785726695`. Shell into it via: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`. Observe environment via: `env | grep -E '(GHA2DB|^PG_|^ES_|^ONLY|INIT|^PROJ)' | sort`. See PVs mounts: `df -h`. Delete pod `kubectl delete pod pod-name`.
- Use `AWS_PROFILE=... ONLY=projname ./k8s/apply_manifest.sh ./k8s/other_manifests/test-devstats-hourly-sync.yaml` to test hourly sync. Shell into pod: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`. Run `devstats`. Delete pod: `kubectl delete pod pod-name`.
- Use `AWS_PROFILE=... PROJ=projname PROJDB=projdb PROJREPO='org/name' INIT=1 ./k8s/apply_manifest.sh ./k8s/other_manifests/test-devstats-provision.yaml`. You can use `ONLYINIT=1` to test bootstraping logs database and users only. Shell into pod: `AWS_PROFILE=... ./k8s/pod_shell.sh pod-name`. Run `./k8s/deploy_all.sh`. Delete pod: `kubectl delete pod pod-name`.
- To deploy next projects skip `INIT=1` (this is used to bootstrap default users and logs database). This is not mandatory, `INIT=1` will not do any harm, it will detect existing users and databases.


# Deploy on Kubernetes

- Run `AWS_PROFILE=... ./k8s/apply_manifest.sh ./k8s/manifests/devstats-pvc.yml` to create presistent volume and persisten volume claim for git repository clones storage. This must be done first. You also need all secrets to be populated via `./k8s/create-secrets.sh`.
- Run `AWS_PROFILE=... PROJ=... PROJDB=... PROJREPO=... INIT=1 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml` to do an initial Kubernetes deployment (bootstraps logs database, users and deploys first project). You can use `ONLYINIT=1` to test bootstraping logs database and users only - that will skip actual first project provision.
- Run `AWS_PROFILE=... PROJ=... PROJDB=... PROJREPO=... ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml` to deploy any next project.
- Run `AWS_PROFILE=... ONLY=projname CRON='8 * * * *' ./k8s/apply_manifest.sh ./k8s/manifests/devstats-hourly-sync.yaml` to create a hourly sync of `projname` at evey hour and 8 minutes.
- To provision all projects do: `AWS_PROFILE=... ./k8s/provision_them_all.sh`, then wait for all `devstats-provision-1...` pods to finish. This can take a *LOT* of time.
- To setup hourly sync for all currently defined project just run: `AWS_PROFILE=... ./k8s/cron_them_all.sh`. Do it after all initial provisioning is finished.
- To cleanup completed pod, use: `AWS_PROFILE=... ./k8s/cleanup_completed_pods.sh`.
- To delete all DevStats cron jobs run: `AWS_PROFILE=... ./k8s/delete_devstats_cron_jobs.sh`.
- To delete and recreate cron jobs run: `AWS_PROFILE=... ./k8s/recreate_cron_jobs.sh`. This uses Helm and `devstats-helm` chart.
