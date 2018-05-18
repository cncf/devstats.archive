# Postgres variables

- Results are saved to [gha_vars](https://github.com/cncf/devstats/blob/master/docs/tables/gha_vars.md) table.
- Key is `name`, values are various columns starting with `value_` - different types are supported.
- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/vars.yaml) (kubernetes example).
- This is `metrics/{{project_name}}/vars.yaml` for other projects.
- They use `vars` [tool](https://github.com/cncf/devstats/blob/master/cmd/vars/vars.go), called [here](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L26) (Kubernetes) or [here](https://github.com/cncf/devstats/blob/master/prometheus/psql.sh#L22) (Prometheus).
- `vars` can also be used for defining per project variables using OS commands results.
- To use command result just provide `command: [your_command, arg1, ..., argN]` in `vars.yaml` file. It will overwrite value if command result is non-empty.
- It can use previous variables by defining `replaces: [[from1, to1], .., [fromN, toN]]`.
- If `from` is `fromN` and `to` is `toN` - then it will replace `[[fromN]]` with:
  - Already defined variable contents `toN` if no special charactes before variable name are used.
  - Environment variable `toN` if used special syntax `$toN`.
  - Direct string value `toN` if used special syntax `:toN`.
- If `from` starts with `:`, `:from` - then it will replace `from` directly, instead of `[[from]]`. This allows replace any text, not only template variables.
- Any replacement `f` -> `t` made creates additional variable `f` with value `t` that can be used in next replacements or next variables.
- All those options are used [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/vars.yaml), [here](https://github.com/cncf/devstats/blob/master/metrics/prometheus/vars.yaml) or [there](https://github.com/cncf/devstats/blob/master/metrics/opencontainers/vars.yaml).
- We can even create conditional partial (conditional on variable name, in this case `hostname`). See this:
```
  - [hostname, os_hostname]
  #- [hostname, ':devstats.cncf.io']
  - [':testsrv=cncftest.io ', ':']
  - [': cncftest.io=testsrv', ':']
  - [':testsrv=', ':<!-- ']
  - [':=testsrv', ': -->']
  - [':prodsrv=devstats.cncf.io ', ':']
  - [': devstats.cncf.io=prodsrv', ':']
  - [':prodsrv=', ':<!-- ']
  - [':=prodsrv', ': -->']
```
- Assume we already have `os_hostname` variable which contains current hostname.
- In first line we replace all `[[hostname]]` with current host name.
- Second line is commented out, but here we're replacing `[[hostname]]` with hardcoded value. We can comment out 1st line and uncomment 2nd to test how it would work on a specific hostname.
- We can use 'test server' markers: `testsrv=[[hostname]] ` and ` [[hostname]]=testsrv` to mark beginning and end of content that will only be inserted when `hostname = 'cncftest.io'`.
- We can use 'production server' markers: `prodsrv=[[hostname]] ` and ` [[hostname]]=prodsrv` to mark beginning and end of content that will only be inserted when `hostname = 'devstats.cncf.io'`.
- See home dashboard projects [panel](https://github.com/cncf/devstats/blob/master/partials/projects.html) for example usage.
- This works like this:
  - Text `testsrv=[[hostname]]` is first replaced with the current hostname, for example: `testsrv=cncftest.io` on the test server.
  - Then we have a direct replacement (marek by replacements starting with `:`) 'testsrv=cncftest.io ' -> '', so finally entire `testsrv=[[hostname]]` is cleared.
  - Similar story happens with `[[hostname]]=testsrv`.
  - That makes content between those markers directly available.
  - Now let's assume we are on the production server, so `hostname=devstats.cncf.io`.
  - Text `testsrv=[[hostname]]` is first replaced with the current hostname, for example: `testsrv=devstats.cncf.io` on the test server.
  - There is no direct replacement for `:testsrv=devstats.cncf.io` (there only is `:prodsrv=devstats.cncf.io` with this hostname).
  - But there is replacement for nonmatching `testsrv` part: `':testsrv=', ':<!-- '`, so finally `testsrv=[[hostname]]` -> `testsrv=devstats.cncf.io` -> `<!-- devstats.cncf.io`.
  - Similar: `[[hostname]]=testsrv` -> `devstats.cncf.io=testsrv` -> `devstats.cncf.io -->`, using `':=testsrv', ': -->'`.
- So finally `testsrv=[[hostname]]` is cleared on the test server and evaluates to `<!-- devstats.cncf.io` on the production.
- `[[hostname]]=testsrv` is cleared on the test server and evaluates to `devstats.cncf.io -->` on the production.
- `prodsrv=[[hostname]]` is cleared on the production server and evaluates to `<!-- cncftest.io` on the test.
- `[[hostname]]=prodsrv` is cleared on the production server and evaluates to `cncftest.io -->` on the test.
