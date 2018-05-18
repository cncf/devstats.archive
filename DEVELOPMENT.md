# Developing locally

- Clone the repo.
- Checkout `production` branch (this is always a final working state on production machines`.
- Create branch from there.
- Follow install instructions for your platform.
- You don't need to have certbot SSL's, Apache proxy (it is only used to provide SSL and proxy to http Grafanas).
- You don't need domain names, you can install locally and just test using "http://127.0.0.1:3001" etc.
- You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here your token value).
- If you really don't want to use GitHub OAuth2 token, specify GHA2DB_GITHUB_OAUTH=- - this will force tokenless operation (via public API), it is a lot more rate limited (60 API points/h) than OAuth2 which gives 5000 API points/h.
- GitHub OAuth token is only needed for `ghapi2db` tool.
