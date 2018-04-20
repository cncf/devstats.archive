GO_LIB_FILES=pg_conn.go error.go mgetc.go map.go threads.go gha.go json.go idb_conn.go time.go context.go exec.go structure.go log.go hash.go unicode.go const.go string.go annotations.go env.go ghapi.go io.go sqlite_conn.go
GO_BIN_FILES=cmd/structure/structure.go cmd/runq/runq.go cmd/gha2db/gha2db.go cmd/db2influx/db2influx.go cmd/gha2db_sync/gha2db_sync.go cmd/z2influx/z2influx.go cmd/import_affs/import_affs.go cmd/annotations/annotations.go cmd/idb_tags/idb_tags.go cmd/idb_backup/idb_backup.go cmd/webhook/webhook.go cmd/devstats/devstats.go cmd/get_repos/get_repos.go cmd/merge_pdbs/merge_pdbs.go cmd/idb_vars/idb_vars.go cmd/replacer/replacer.go cmd/pdb_vars/pdb_vars.go cmd/ghapi2db/ghapi2db.go cmd/idb_tst/idb_tst.go cmd/sqlitedb/sqlitedb.go
GO_TEST_FILES=context_test.go gha_test.go map_test.go mgetc_test.go threads_test.go time_test.go unicode_test.go string_test.go regexp_test.go annotations_test.go env_test.go
GO_DBTEST_FILES=pg_test.go idb_test.go series_test.go metrics_test.go
GO_LIBTEST_FILES=test/compare.go test/time.go
GO_BIN_CMDS=devstats/cmd/structure devstats/cmd/runq devstats/cmd/gha2db devstats/cmd/db2influx devstats/cmd/gha2db_sync devstats/cmd/z2influx devstats/cmd/import_affs devstats/cmd/annotations devstats/cmd/idb_tags devstats/cmd/idb_backup devstats/cmd/webhook devstats/cmd/devstats devstats/cmd/get_repos devstats/cmd/merge_pdbs devstats/cmd/idb_vars devstats/cmd/replacer devstats/cmd/pdb_vars devstats/cmd/ghapi2db devstats/cmd/idb_tst devstats/cmd/sqlitedb
#GO_ENV=CGO_ENABLED=1
GO_ENV=CGO_ENABLED=0
# -ldflags '-s -w': create release binary - without debug info
#GO_BUILD=go build
O_BUILD=go build -ldflags '-s -w' -race
GO_BUILD=go build -ldflags '-s -w'
#  -ldflags '-s': instal stripped binary
#GO_INSTALL=go install
GO_INSTALL=go install -ldflags '-s'
GO_FMT=gofmt -s -w
GO_LINT=golint -set_exit_status
GO_VET=go vet
GO_CONST=goconst -ignore 'vendor'
GO_IMPORTS=goimports -w
GO_USEDEXPORTS=usedexports -ignore 'sqlitedb.go|vendor'
GO_ERRCHECK=errcheck -asserts -ignore '[FS]?[Pp]rint*' -ignoretests
GO_TEST=go test
BINARIES=structure runq gha2db db2influx z2influx gha2db_sync import_affs annotations idb_tags idb_backup webhook devstats get_repos merge_pdbs idb_vars replacer pdb_vars ghapi2db idb_tst sqlitedb
CRON_SCRIPTS=cron/cron_db_backup.sh cron/cron_db_backup_all.sh scripts/net_tcp_config.sh
UTIL_SCRIPTS=devel/wait_for_command.sh devel/cronctl.sh devel/sync_lock.sh devel/sync_unlock.sh
GIT_SCRIPTS=git/git_reset_pull.sh git/git_files.sh git/git_tags.sh
STRIP=strip

all: check ${BINARIES}

structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o structure cmd/structure/structure.go

runq: cmd/runq/runq.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o runq cmd/runq/runq.go

gha2db: cmd/gha2db/gha2db.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2db cmd/gha2db/gha2db.go

db2influx: cmd/db2influx/db2influx.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o db2influx cmd/db2influx/db2influx.go

z2influx: cmd/z2influx/z2influx.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o z2influx cmd/z2influx/z2influx.go

import_affs: cmd/import_affs/import_affs.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o import_affs cmd/import_affs/import_affs.go

gha2db_sync: cmd/gha2db_sync/gha2db_sync.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2db_sync cmd/gha2db_sync/gha2db_sync.go

devstats: cmd/devstats/devstats.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o devstats cmd/devstats/devstats.go

annotations: cmd/annotations/annotations.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o annotations cmd/annotations/annotations.go

idb_tags: cmd/idb_tags/idb_tags.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o idb_tags cmd/idb_tags/idb_tags.go

idb_backup: cmd/idb_backup/idb_backup.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o idb_backup cmd/idb_backup/idb_backup.go

idb_tst: cmd/idb_tst/idb_tst.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o idb_tst cmd/idb_tst/idb_tst.go

webhook: cmd/webhook/webhook.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o webhook cmd/webhook/webhook.go

get_repos: cmd/get_repos/get_repos.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o get_repos cmd/get_repos/get_repos.go

merge_pdbs: cmd/merge_pdbs/merge_pdbs.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o merge_pdbs cmd/merge_pdbs/merge_pdbs.go

idb_vars: cmd/idb_vars/idb_vars.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o idb_vars cmd/idb_vars/idb_vars.go

pdb_vars: cmd/pdb_vars/pdb_vars.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o pdb_vars cmd/pdb_vars/pdb_vars.go

ghapi2db: cmd/ghapi2db/ghapi2db.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o ghapi2db cmd/ghapi2db/ghapi2db.go

replacer: cmd/replacer/replacer.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o replacer cmd/replacer/replacer.go

sqlitedb: cmd/sqlitedb/sqlitedb.go ${GO_LIB_FILES}
	 ${GO_BUILD} -o sqlitedb cmd/sqlitedb/sqlitedb.go

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

data:
	cp -v ${UTIL_SCRIPTS} ${GOPATH}/bin
	[ ! -f /tmp/deploy.wip ] || exit 6
	wait_for_command.sh devstats 3600 || exit 7
	mkdir /etc/gha2db 2>/dev/null || echo "..."
	chmod 777 /etc/gha2db 2>/dev/null || echo "..."
	rm -fr /etc/gha2db/* || exit 1
	cp -R metrics/ /etc/gha2db/metrics/ || exit 2
	cp -R util_sql/ /etc/gha2db/util_sql/ || exit 3
	cp -R docs/ /etc/gha2db/docs/ || exit 4
	cp -R partials/ /etc/gha2db/partials/ || exit 5
	cp -R scripts/ /etc/gha2db/scripts/ || exit 6
	cp cncf.yaml kubernetes.yaml projects.yaml /etc/gha2db/ || exit 7
	cp devel/*.txt /etc/gha2db/ || exit 8

install: check ${BINARIES} data
	${GO_INSTALL} ${GO_BIN_CMDS}
	cp -v ${CRON_SCRIPTS} ${GOPATH}/bin
	cp -v ${GIT_SCRIPTS} ${GOPATH}/bin

strip: ${BINARIES}
	${STRIP} ${BINARIES}

clean:
	rm -f ${BINARIES}

.PHONY: test
