# `gha_vars` table

- This is a special table that holds PostgreS variables defined by [pdb_vars](https://github.com/cncf/devstats/blob/master/cmd/prb_vars/pdb_vars.go) tool.
- More info about `pdb_vars` tool [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
- Key is `name`, values are various columns starting with `value_` - different types are supported.
- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml) (kubernetes example).
- Its primary key is `name`. Max length is 100 characters.

# Columns

- `name`: Variable name. Max var name length is 100 characters.
- `value_i`: Integer value. Bigint.
- `value_f`: Float value. Double precision.
- `value_s`: String value. Unlimited length.
- `value_dt`: Datetime value. 
