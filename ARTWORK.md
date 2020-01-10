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
