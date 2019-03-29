GO_FMT=gofmt -s -w
GO_LINT=golint -set_exit_status
GO_VET=go vet
GO_CONST=goconst -ignore 'vendor'
GO_IMPORTS=goimports -w
GO_USEDEXPORTS=usedexports -ignore 'sqlitedb.go|vendor'
GO_ERRCHECK=errcheck -asserts -ignore '[FS]?[Pp]rint*' -ignoretests

GO_TEST_FILES=metrics_test.go
GO_TEST=go test
GO_TEST_ENV=PG_DB=dbtest GHA2DB_PROJECT=kubernetes GHA2DB_LOCAL=1

CRON_SCRIPTS=cron/cron_db_backup.sh cron/cron_db_backup_all.sh cron/refresh_mviews.sh cron/sysctl_config.sh cron/backup_artificial.sh cron/restart_dbs.sh cron/ensure_service_active.sh
UTIL_SCRIPTS=devel/wait_for_command.sh devel/cronctl.sh devel/sync_lock.sh devel/sync_unlock.sh devel/db.sh devel/all_projs.sh devel/all_dbs.sh
GIT_SCRIPTS=git/git_reset_pull.sh git/git_files.sh git/git_tags.sh git/last_tag.sh

ifdef GHA2DB_DATADIR
DATADIR=${GHA2DB_DATADIR}
else
DATADIR=/etc/gha2db
endif

all: check test

fmt: ${GO_TEST_FILES}
	./for_each_go_file.sh "${GO_FMT}"

lint: ${GO_TEST_FILES}
	./for_each_go_file.sh "${GO_LINT}"

vet: ${GO_TEST_FILES}
	./vet_files.sh "${GO_VET}"

imports: ${GO_TEST_FILES}
	./for_each_go_file.sh "${GO_IMPORTS}"

const: ${GO_TEST_FILES}
	${GO_CONST} ./...

usedexports: ${GO_TEST_FILES}
	${GO_USEDEXPORTS} ./...

errcheck: ${GO_TEST_FILES}
	${GO_ERRCHECK} $(go list ./... | grep -v /vendor/)

test:
	${GO_TEST_ENV} ${GO_TEST} ${GO_TEST_FILES}

check: fmt lint imports vet const usedexports errcheck

util_scripts:
	cp -v ${UTIL_SCRIPTS} ${GOPATH}/bin

data: util_scripts
	[ ! -f /tmp/deploy.wip ] || exit 1
	wait_for_command.sh devstats 600 || exit 2
	wait_for_command.sh devstats_others 600 || exit 3
	wait_for_command.sh devstats_kubernetes 600 || exit 4
	wait_for_command.sh devstats_allprj 600 || exit 5
	make copydata

copydata: util_scripts
	mkdir ${DATADIR} 2>/dev/null || echo "..."
	chmod 777 ${DATADIR} 2>/dev/null || echo "..."
	rm -fr ${DATADIR}/* || exit 3
	cp -R metrics/ ${DATADIR}/metrics/ || exit 4
	cp -R util_sql/ ${DATADIR}/util_sql/ || exit 5
	cp -R util_sh/ ${DATADIR}/util_sh/ || exit 6
	cp -R docs/ ${DATADIR}/docs/ || exit 7
	cp -R partials/ ${DATADIR}/partials/ || exit 8
	cp -R scripts/ ${DATADIR}/scripts/ || exit 9
	cp devel/*.txt ${DATADIR}/ || exit 11
	cp github_users.json *.yaml ${DATADIR}/ || exit 12
	cp cdf/projects.yaml ${DATADIR}/cdf_projects.yaml || exit 13

install: data
	cp -v ${CRON_SCRIPTS} ${GOPATH}/bin
	cp -v ${GIT_SCRIPTS} ${GOPATH}/bin

.PHONY: test
