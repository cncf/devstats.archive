# Updating icons/artwork

- If given artwork is not merged yet, then go to `~/cncf/artwort` and `git checkout feature-branch-name`.
- Make sure you have the newest `cncf/artwork` in `~/dev/cncf/artwork` and `cdfoundation/artwork` in `~/dev/cdfoundation/artwork`.
- Edit all files marked with `ARTWORK`, uncomment `TODO` and update icons: `./find.sh . '*' ARTWORK`.
- Update: `devel/deploy_all.sh`.
- Update & run: `./apache/www/copy_icons.sh`. This is for local static pages.
- Update & run: `./grafana/create_images.sh`. This is for update repo, so new docker images can be build.
- Update & run: `./grafana/copy_artwork_icons.sh`. This is for update local Grafanas.
- or use `./devel/icons_all.sh`.
- Run: `./grafana/restart_all_grafanas.sh` (this is optional).
- Check if new artwork is available for all projects and for the main page.
- Update `cncf/devstats-helm`:`devstats-helm/values.yaml`.
- Update `cncf/devstats-helm-lf`:`devstats-helm/values.yaml`.


# Other repos

- Run `./find.sh . '*' ARTWORK` on `github.com/cncf/devstats-helm`, `github.com/cncf/devstats-helm-lf`, `github.com/cncf/devstats-helm-example`, `github.com/cncf/devstats-docker-images` and `github.com/cncf/devstats-example`.


# Helm/Kubernetes deployment

- Generate new static images, go to `cncf/devstats-docker-images`: `DOCKER_USER=... SKIP_FULL=1 SKIP_MIN=1 SKIP_TESTS=1 SKIP_GRAFANA=1 SKIP_PATRONI=1 SKIP_REPORTS=1 SKIP_API=1 ./images/build_images.sh`.
- After new static images are generated, replace old static pods: `k get po -A | grep static` and then `k delete po -n devstats-test/devstats-prod devstats-static-prod-xxxxxxxxxx-yyyyy`.
- Go to `cncf/devstats-k8s-lf/util` on both `prod` and `test` nodes (`master` and `node-0`), run: `[ITER=1] ./delete_objects.sh po devstats-grafana-`.
