# Excluding bots

- You can put excluding bots partial `{{exclude_bots}}` anywhere in the metric SQL.
- You should put exclude bots partial inside parentheses like for example: `(lower(actor_login) {{exclude_bots}})`.
- `{{exclude_bots}}` will be replaced with the contents of the [util_sql/exclude_bots.sql](https://github.com/cncf/devstats/blob/master/util_sql/exclude_bots.sql).
- Currently is is defined as: `not like all(array['googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%'])`.
- Most actor related metrics use this.
