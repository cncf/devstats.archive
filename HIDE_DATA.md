# How to hide data

If you do not want your data to be shown:

- Clone `cncf/devstats` locally.
- You need to add SHA1 hash of the data you want to hide.
- You can use online [SHA1 tool](http://www.sha1-online.com).
- For example `hide_me` gives: `f6f9480eb4f34372a4860c829cc5bc5fc1549a1c` sha1 hash.
- Add this hash value to [hide.csv](https://github.com/cncf/devstats/blob/master/hide/hide.csv) file and create PR.
- You can also use `devstats` [hide_data](https://github.com/cncf/devstats/blob/master/cmd/hide_data/hide_data.go) tool.
- `make hide_data && hide_data your_data other_data yet_another_data ...`. It will generate hashes and add them to `hide.csv` for you.
- After you add all data to `hide.csv` file, create PR.
- That way your sensitive data won't be visible in a PR.
- We will remove requested informations and merge your PR.
