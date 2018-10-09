# Grafana SQLite database manipulations

- To dump SQLite database to check structure use: `./devel/sqlite_dump.sh suffix`, it will produce `grafana_suffix.sql` file.
- To import JSONs into Grafana SQLite database use: `GRAFANA=suffix devel/import_jsons_to_sqlite.sh path/to/jsons/*.json`. This will temporarily stop given Grafana instance.
- To mass import all projects all dashboards use: `./devel/put_all_charts.sh`, then check if everything is OK, and then eventually: `./devel/put_all_charts_cleanup.sh`.
- To delete grafana dashboards by their uid(s) use: `GRAFANA=suffix devel/import_jsons_to_sqlite.sh 'uid1,uid2,..,uidN'`. This will temporarily stop given Grafana instance.
- To get all dashboards from SQLite and save them as JSONs use: `ONLY=projectname devel/get_all_sqlite_jsons.sh`. Skip `ONLY=...` to process all projects. This removes current dashboards JSONs and replaces them JSONs from the database.
- To get some JSONs from SQLite use `GRAFANA=suffix devel/get_from_sqlite.sh path/to/jsons/*.json`. This will overwrite JSONs given as arguments if they differ from those from the database.
- To import all project's dashboards JSONs into a temporary database files (stored in the current directory) use `ONLY=project devel/import_all_sqlite_jsons.sh`. Skip `ONLY=...` to process all projects. This is not updating real Grafana database(s).
- All tools save `.json` -> `.json.was` if modification is made. To find all `.json.was` files and move them back to `.json` use: `devel/update_from_sqlite.sh`.
- When you made manul changes on grafana.db file use: `GRAFANA=suffix devel/update_sqlite_manually.sh your_file.db` to update given grafana DB using this file.

# Example

- Modify some Kubernetes dashboards in `grafana/dashboards/kubernetes/`.
- Now import them to Grafana (specify all files, changed ones will be saved with `.was` extension), skip `dashboards.json` (Home dashboard) because it contains a lot of code auto-generated from Postgres variables, and we don't want to get JSON with this code already generated.
```
GRAFANA=k8s devel/import_jsons_to_sqlite.sh `find grafana/dashboards/kubernetes/ -iname "*.json" -not -iname "dashboards.json"`
```
- Check [Grafana](https://k8s.teststats.cncf.io) if all modifications are OK.
- If ok then we can remove all backups: `git status`, followed by `find . -iname "*.was" -exec rm -f "{}" \;`, `rm grafana.k8s.db*`, `./grafana/copy_grafana_dbs.sh`, `git status`.
- Now JSONs names could chage due to renames. Proper JSON name is `grafana/dashboards/project/title-slug.json`.
- Import all JSONs from SQLite DB now: `ONLY=kubernetes devel/get_all_sqlite_jsons.sh`.
- Restore original home dashboard: `git checkout grafana/dashboards/kubernetes/dashboards.json`.
- `git status` - You will see deleted files and new untracked files when you renamed any dashbord. This is exactly what you want - json names changed.
- Do `git diff` to make sure all is OK and then `git add .`, `git status`, `git diff HEAD^`.
- Finally `git commit -sm "..."`, `git push`.
