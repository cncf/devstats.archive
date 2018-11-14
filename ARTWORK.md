# Updating icons/artwork

- Make sure you have the newest `cncf/artwork` in `~/dev/cncf/artwork`.
- Edit all files marked with `ARTWORK`, uncoimment `TODO` and update icons.
- Update: `devel/deploy_all.sh`.
- Update & run: `./apache/www/copy_icons.sh`.
- Update & run: `./grafana/create_images.sh`.
- Update & run: `./grafana/copy_artwork_icons.sh`.
- Run: `./grafana/restart_all_grafanas.sh`.
- Check if new artwork is available for all projects and for the main page.
