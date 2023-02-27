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


# Updating shared grafana resource

- Execute: `tar cfv img.tar grafana/img/ && sftp root@node-2`, `mput img.tar`. Once done on `node-2`: `rm -f img.tar`.
- Execute on node-2: `k get po -A | grep devstats-static-test`, `k cp -n devstats-test img.tar devstats-static-test-5bcb77dbc5-sw72s:/img.tar`, `k exec -itn devstats-test devstats-static-test-5bcb77dbc5-sw72s -- bash`, `tar xvf img.tar && cp -v /grafana/img/* /usr/share/nginx/html/backups/grafana/img/ && rm /img.tar && exit`.
- Execute on node-2: `k get po -A | grep devstats-static-prod`, `k cp -n devstats-prod img.tar devstats-static-prod-5b96c8b9f9-fk875:/img.tar`, `k exec -itn devstats-prod devstats-static-prod-5b96c8b9f9-fk875 -- bash`, `tar xvf img.tar && cp -v /grafana/img/* /usr/share/nginx/html/backups/grafana/img/ && rm /img.tar && exit`.
- Execute on node-2: `rm -f img.tar; k delete po -n devstats-test devstats-static-test-5bcb77dbc5-sw72s; k delete po -n devstats-prod devstats-static-prod-5b96c8b9f9-fk875`.
- See `Update shared Grafana data` in `ADDING_NEW_PROJECT.md`.
