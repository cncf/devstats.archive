GO_LIB_FILES=pg_conn.go error.go mgetc.go map.go threads.go gha.go json.go time.go context.go exec.go structure.go log.go hash.go unicode.go const.go string.go annotations.go env.go ghapi.go io.go tags.go yaml.go es_conn.go ts_points.go convert.go
GO_BIN_FILES=cmd/structure/structure.go cmd/runq/runq.go cmd/gha2db/gha2db.go cmd/calc_metric/calc_metric.go cmd/gha2db_sync/gha2db_sync.go cmd/import_affs/import_affs.go cmd/annotations/annotations.go cmd/tags/tags.go cmd/webhook/webhook.go cmd/devstats/devstats.go cmd/get_repos/get_repos.go cmd/merge_dbs/merge_dbs.go cmd/replacer/replacer.go cmd/vars/vars.go cmd/ghapi2db/ghapi2db.go cmd/columns/columns.go cmd/hide_data/hide_data.go cmd/sqlitedb/sqlitedb.go cmd/website_data/website_data.go cmd/sync_issues/sync_issues.go cmd/devstats_api_server/devstats_api_server.go cmd/gha2es/gha2es.go
GO_TEST_FILES=context_test.go gha_test.go map_test.go mgetc_test.go threads_test.go time_test.go unicode_test.go string_test.go regexp_test.go annotations_test.go env_test.go convert_test.go
GO_DBTEST_FILES=pg_test.go series_test.go metrics_test.go
GO_LIBTEST_FILES=test/compare.go test/time.go
GO_BIN_CMDS=devstats/cmd/structure devstats/cmd/runq devstats/cmd/gha2db devstats/cmd/calc_metric devstats/cmd/gha2db_sync devstats/cmd/import_affs devstats/cmd/annotations devstats/cmd/tags devstats/cmd/webhook devstats/cmd/devstats devstats/cmd/get_repos devstats/cmd/merge_dbs devstats/cmd/replacer devstats/cmd/vars devstats/cmd/ghapi2db devstats/cmd/columns devstats/cmd/hide_data devstats/cmd/sqlitedb devstats/cmd/website_data devstats/cmd/sync_issues devstats/cmd/devstats_api_server devstats/cmd/gha2es
GO_DOCKER_BIN_CMDS=devstats/cmd/structure devstats/cmd/gha2db devstats/cmd/calc_metric devstats/cmd/gha2db_sync devstats/cmd/import_affs devstats/cmd/annotations devstats/cmd/tags devstats/cmd/devstats devstats/cmd/get_repos devstats/cmd/vars devstats/cmd/ghapi2db devstats/cmd/columns devstats/cmd/gha2es devstats/cmd/runq devstats/cmd/replacer
#for race CGO_ENABLED=1
#GO_ENV=CGO_ENABLED=1
GO_ENV=CGO_ENABLED=0
# -ldflags '-s -w': create release binary - without debug info
GO_BUILD=go build -ldflags '-s -w'
#GO_BUILD=go build -ldflags '-s -w' -race
#  -ldflags '-s': instal stripped binary
#GO_INSTALL=go install
#For static gcc linking
GCC_STATIC=
#GCC_STATIC=-ldflags '-extldflags "-static"'
GO_INSTALL=go install -ldflags '-s'
GO_FMT=gofmt -s -w
GO_LINT=golint -set_exit_status
GO_VET=go vet
GO_CONST=goconst -ignore 'vendor'
GO_IMPORTS=goimports -w
GO_USEDEXPORTS=usedexports -ignore 'sqlitedb.go|vendor'
GO_ERRCHECK=errcheck -asserts -ignore '[FS]?[Pp]rint*' -ignoretests
GO_TEST=go test
BINARIES=structure gha2db calc_metric gha2db_sync import_affs annotations tags webhook devstats get_repos merge_dbs replacer vars ghapi2db columns hide_data website_data sync_issues devstats_api_server gha2es runq sqlitedb
DOCKER_BINARIES=structure gha2db calc_metric gha2db_sync import_affs annotations tags devstats get_repos vars ghapi2db columns gha2es runq replacer
CRON_SCRIPTS=cron/cron_db_backup.sh cron/cron_db_backup_all.sh cron/refresh_mviews.sh cron/sysctl_config.sh cron/backup_artificial.sh cron/restart_dbs.sh cron/ensure_service_active.sh
UTIL_SCRIPTS=devel/wait_for_command.sh devel/cronctl.sh devel/sync_lock.sh devel/sync_unlock.sh devel/db.sh devel/all_projs.sh devel/all_dbs.sh
GIT_SCRIPTS=git/git_reset_pull.sh git/git_files.sh git/git_tags.sh git/last_tag.sh
STRIP=strip

all: check ${BINARIES}

dockerbin: ${DOCKER_BINARIES}

structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o structure cmd/structure/structure.go

runq: cmd/runq/runq.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o runq cmd/runq/runq.go

gha2db: cmd/gha2db/gha2db.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2db cmd/gha2db/gha2db.go

gha2es: cmd/gha2es/gha2es.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2es cmd/gha2es/gha2es.go

calc_metric: cmd/calc_metric/calc_metric.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o calc_metric cmd/calc_metric/calc_metric.go

import_affs: cmd/import_affs/import_affs.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o import_affs cmd/import_affs/import_affs.go

gha2db_sync: cmd/gha2db_sync/gha2db_sync.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2db_sync cmd/gha2db_sync/gha2db_sync.go

devstats: cmd/devstats/devstats.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o devstats cmd/devstats/devstats.go

annotations: cmd/annotations/annotations.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o annotations cmd/annotations/annotations.go

tags: cmd/tags/tags.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o tags cmd/tags/tags.go

columns: cmd/columns/columns.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o columns cmd/columns/columns.go

webhook: cmd/webhook/webhook.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o webhook cmd/webhook/webhook.go

get_repos: cmd/get_repos/get_repos.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o get_repos cmd/get_repos/get_repos.go

merge_dbs: cmd/merge_dbs/merge_dbs.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o merge_dbs cmd/merge_dbs/merge_dbs.go

vars: cmd/vars/vars.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o vars cmd/vars/vars.go

ghapi2db: cmd/ghapi2db/ghapi2db.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o ghapi2db cmd/ghapi2db/ghapi2db.go

sync_issues: cmd/sync_issues/sync_issues.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o sync_issues cmd/sync_issues/sync_issues.go

replacer: cmd/replacer/replacer.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o replacer cmd/replacer/replacer.go

hide_data: cmd/hide_data/hide_data.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o hide_data cmd/hide_data/hide_data.go

website_data: cmd/website_data/website_data.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o website_data cmd/website_data/website_data.go

devstats_api_server: cmd/devstats_api_server/devstats_api_server.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o devstats_api_server cmd/devstats_api_server/devstats_api_server.go

sqlitedb: cmd/sqlitedb/sqlitedb.go ${GO_LIB_FILES}
	 ${GO_BUILD} ${GCC_STATIC} -o sqlitedb cmd/sqlitedb/sqlitedb.go

fmt: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_FMT}"

lint: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_LINT}"

vet: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./vet_files.sh "${GO_VET}"

imports: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_IMPORTS}"

const: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	${GO_CONST} ./...

usedexports: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	${GO_USEDEXPORTS} ./...

errcheck: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	${GO_ERRCHECK} $(go list ./... | grep -v /vendor/)

test:
	${GO_TEST} ${GO_TEST_FILES}

dbtest:
	${GO_TEST} ${GO_DBTEST_FILES}

check: fmt lint imports vet const usedexports errcheck

util_scripts:
	cp -v ${UTIL_SCRIPTS} ${GOPATH}/bin

data: util_scripts
	[ ! -f /tmp/deploy.wip ] || exit 1
	wait_for_command.sh devstats 3600 || exit 2
	make copydata

copydata: util_scripts
	mkdir /etc/gha2db 2>/dev/null || echo "..."
	chmod 777 /etc/gha2db 2>/dev/null || echo "..."
	rm -fr /etc/gha2db/* || exit 3
	cp -R metrics/ /etc/gha2db/metrics/ || exit 4
	cp -R util_sql/ /etc/gha2db/util_sql/ || exit 5
	cp -R util_sh/ /etc/gha2db/util_sh/ || exit 6
	cp -R docs/ /etc/gha2db/docs/ || exit 7
	cp -R partials/ /etc/gha2db/partials/ || exit 8
	cp -R scripts/ /etc/gha2db/scripts/ || exit 9
	cp projects.yaml /etc/gha2db/ || exit 10
	cp devel/*.txt /etc/gha2db/ || exit 11
	cp github_users.json /etc/gha2db/ || exit 12
	cp companies.yaml /etc/gha2db/ || exit 13
	cp linux.yaml /etc/gha2db/ || exit 14

install: ${BINARIES} data
	${GO_INSTALL} ${GO_BIN_CMDS}
	cp -v ${CRON_SCRIPTS} ${GOPATH}/bin
	cp -v ${GIT_SCRIPTS} ${GOPATH}/bin

dockerinstall: ${DOCKER_BINARIES} copydata
	mkdir /etc/gha2db/docker 2>/dev/null || echo "..."
	chmod 777 /etc/gha2db/docker 2>/dev/null || echo "..."
	cp docker/docker_projects.yaml /etc/gha2db/docker/ || exit 10
	${GO_INSTALL} ${GO_DOCKER_BIN_CMDS}
	cp -v ${CRON_SCRIPTS} ${GOPATH}/bin
	cp -v ${GIT_SCRIPTS} ${GOPATH}/bin

deploy:
	./deploy.sh || exit 1

strip: ${BINARIES}
	${STRIP} ${BINARIES}

clean:
	rm -f ${BINARIES}

.PHONY: test
