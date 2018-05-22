# How to hide data

If you do not want your data to be shown:

- Clone `cncf/devstats` locally.
- You need to add SHA256 hash of the data you want to hide.
- You can use online [tool](https://hash.online-convert.com/sha256-generator).
- For example `hide_me` gives: `10d527f453c18414dc29e2b0372da5111baea1a9935367e0ad8e4f3fa9117171` sha256 hash.
- Add this hash value to [hide.csv](https://github.com/cncf/devstats/blob/master/hide.csv) file and create PR.
- You can also use `devstats` [hide_data](https://github.com/cncf/devstats/blob/master/cmd/hide_data/hide_data.go) tool.
- `make hide_hash && ./hide_data your_data other_data yet_another_data ...`. It will generate hashes and add them to `hide.csv` for you.
- After you add all data to hide, create PR with modified `hide.csv` file.
- That way your sensitive data won't be visible in a PR.
- We will remove requested informations and merge your PR.
