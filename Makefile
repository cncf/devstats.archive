GO_LIB_FILES=pg_conn.go error.go mgetc.go map.go threads.go gha.go json.go idb_conn.go time.go context.go exec.go structure.go log.go hash.go unicode.go
GO_BIN_FILES=cmd/structure/structure.go cmd/runq/runq.go cmd/gha2db/gha2db.go cmd/db2influx/db2influx.go cmd/gha2db_sync/gha2db_sync.go cmd/z2influx/z2influx.go cmd/import_affs/import_affs.go
GO_TEST_FILES=context_test.go gha_test.go map_test.go mgetc_test.go threads_test.go time_test.go unicode_test.go
GO_DBTEST_FILES=pg_test.go idb_test.go metrics_test.go
GO_LIBTEST_FILES=test/compare.go test/time.go
GO_BIN_CMDS=k8s.io/test-infra/gha2db/cmd/structure k8s.io/test-infra/gha2db/cmd/runq k8s.io/test-infra/gha2db/cmd/gha2db k8s.io/test-infra/db2influx/cmd/db2influx k8s.io/test-infra/db2influx/cmd/gha2db_sync k8s.io/test-infra/cmd/z2influx k8s.io/test-infra/import_affs/import_affs
GO_ENV=CGO_ENABLED=0
GO_BUILD=go build
GO_INSTALL=go install
GO_FMT=gofmt -s -w
GO_LINT=golint
GO_VET=go vet
GO_IMPORTS=goimports -w
GO_TEST=go test
BINARIES=structure runq gha2db db2influx z2influx gha2db_sync import_affs
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

fmt: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_FMT}"

lint: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_LINT}"

vet: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_VET}"

imports: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES} ${GO_LIBTEST_FILES}
	./for_each_go_file.sh "${GO_IMPORTS}"

test:
	${GO_TEST} ${GO_TEST_FILES}

dbtest:
	${GO_TEST} ${GO_DBTEST_FILES}

check: fmt lint imports vet

data:
	mkdir /etc/gha2db 2>/dev/null || echo "/etc/gha2db already exists, ok"
	mkdir /etc/gha2db/metrics 2>/dev/null || echo "/etc/gha2db/metrics already exists, ok"
	cp metrics/* /etc/gha2db/metrics/

install: check strip data ${BINARIES}
	#${GO_INSTALL} ${GO_BIN_CMDS}
	cp -v ${BINARIES} cron_gha2db_sync.sh /usr/bin

strip: ${BINARIES}
	${STRIP} ${BINARIES}

clean:
	rm -f structure runq gha2db db2influx z2influx gha2db_sync import_affs

.PHONY: test
