# devstats installation on Ubuntu

Prerequisites:
- FreeBSD (tested on FreeBSD 11.1 amd64)
- [golang](https://golang.org), this tutorial uses Go 1.9
    - 'pkg install bash git go'
    - 'chsh (change to /usr/local/bin/bash)'
    - 'mkdir ~/dev; mkdir ~/dev/go; cd ~/dev/go; mkdir pkg bin src'
1. Configure Go:
    - For example add to '~/.profile':
     ```
     GOPATH=$HOME/dev/go; export GOPATH
     PATH=$PATH:$GOPATH/bin; export PATH
     ```
    - Update your '~/.netrc':
    ```
    machine github.com
      login <user>
      password <password>
    ```
    - Logout and login again.
    - [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
    - [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
    - [goconst](https://github.com/jgautheron/goconst): `go get github.com/jgautheron/goconst/cmd/goconst`
    - [usedexports](https://github.com/jgautheron/usedexports): `go get github.com/jgautheron/usedexports`
    - [errcheck](https://github.com/kisielk/errcheck): `go get github.com/kisielk/errcheck`
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`
2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`, cd `devstats`
3. If you want to make changes and PRs, please clone `devstats` from GitHub UI, and clone your forked version instead, like this:
    - `git clone https://github.com/your_github_username/devstats.git`
6. Go to devstats directory, so you are in `~/dev/go/src/devstats` directory and compile binaries:
    - `make`
7. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.
8. Install binaries & metrics:
    - `sudo mkdir /etc/gha2db`
    - `sudo chmod 777 /etc/gha2db`
    - `sudo make install`

To be continued . . .
