# Updating icons/artwork

- Make sure you have the newest `cncf/artwork` in `~/dev/cncf/artwork` and `cdfoundation/artwork` in `~/dev/cdfoundation/artwork`.
- Edit all files marked with `ARTWORK`, uncomment `TODO` and update icons: `./find.sh . '*' ARTWORK`.
- Update: `devel/deploy_all.sh`.
- Update & run: `./apache/www/copy_icons.sh`.
- Update & run: `./grafana/create_images.sh`.
- Update & run: `./grafana/copy_artwork_icons.sh`.
- Run: `./grafana/restart_all_grafanas.sh`.
- Check if new artwork is available for all projects and for the main page.


# Other repos

- Run `./find.sh . '*' ARTWORK` on `github.com/cncf/devstats-helm-lf` and `github.com/cncf/devstats-k8s-lf`.
