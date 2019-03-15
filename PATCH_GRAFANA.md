# Patching Grafana

- `cd $GOPATH/src/github.com/grafana`.
- `git clone https://github.com/grafana/grafana.git`.
- `cd grafana`.
- `git reset --hard`.
- `git pull`.
- `git checkout -b patching`.
- `git apply $GOPATH/src/devstats/grafana/patches/teamplate_variable_value_optional_remove_from_url.patch`.
- `git diff`.
- `go run build.go setup`.
- `go run build.go build`.
- `apt install npm`.
- `npm install -g yarn`.
- `yarn install --pure-lockfile`.
- `yarn start` (blocks one terminal).
- `go get github.com/Unknwon/bra`
- `bra run` (blocks one terminal).
- `npm run jest`.
- `npm run karma`.
- `npm run test`
- `gem install fpm`
- `apt install rpm`.
- `go run build.go build package` (takes a long time).
- `cp dist/grafanaXXXXX.deb ~/dev/go/src/devstats`.
- `cd $GOPATH/src/devstats`.
- `./devel/update_grafanas.sh grafanaXXXXX.deb`.
- `rm -f rafanaXXXXX.deb`.

Contrib must be started manually:
- `cd ~/dev/cncf/contributors/`.
- `./grafana.sh &`.

