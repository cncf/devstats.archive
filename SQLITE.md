# Grafana SQLite database manipulations

- To dump SQLite database to check structure use: `./devel/sqlite_dump.sh suffix`, it will produce `grafana_suffix.sql` file.
- To import JSONs into Grafana SQLite database use: `GRAFANA=suffix devel/import_jsons_to_sqlite.sh path/to/jsons/*.json`. This will temporarily stop given Grafana instance.
- To get all dashboards from SQLite and save them as JSONs use: `ONLY=projectname devel/get_all_sqlite_jsons.sh`. Skip `ONLY=...` to process all projects. This removes current dashboards JSONs and replaces them JSONs from the database.
- To get some JSONs from SQLite use `GRAFANA=suffix devel/get_from_sqlite.sh path/to/jsons/*.json`. This will overwrite JSONs given as arguments if they differ from those from the database.
- To import all project's dashboards JSONs into a temporary database files (stored in the current directory) use `ONLY=project devel/import_all_sqlite_jsons.sh`. Skip `ONLY=...` to process all projects. This is not updating real Grafana database(s).
- All tools save `.json` -> `.json.was` if modification is made. To find all `.json.was` files and move them back to `.json` use: `devel/update_from_sqlite.sh`.
