# GitHub (GHAPI) datasource details

- You need to have `/etc/github/oauth` file created on your server, this file should contain OAuth token.
- If you want to use multiple tokens, create `/etc/github/oauths` file that contain list of comma separated OAuth keys.
- Without this file you are limited to 60 API calls, see [GitHub info](https://developer.github.com/v3/#rate-limiting).
- You can force using unauthorized acces by setting environment variable `GHA2DB_GITHUB_OAUTH` to `-` - this is not recommended.
- When using OAuth file, you are allowed to use 5000 API points/hour.
