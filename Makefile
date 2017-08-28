GO_LIB_FILES=pg_conn.go error.go mgetc.go map.go threads.go gha.go json.go idb_conn.go time_stuff.go context.go exec.go
GO_BIN_FILES=cmd/structure/structure.go cmd/runq/runq.go cmd/gha2db/gha2db.go cmd/db2influx/db2influx.go cmd/sync/sync.go
GO_TEST_FILES=test/context_test.go test/gha_test.go
GO_DBTEST_FILES=test/pg_test.go
GO_BIN_CMDS=k8s.io/test-infra/gha2db/cmd/structure k8s.io/test-infra/gha2db/cmd/runq k8s.io/test-infra/gha2db/cmd/gha2db k8s.io/test-infra/db2influx/cmd/db2influx k8s.io/test-infra/db2influx/cmd/sync
GO_ENV=CGO_ENABLED=0
GO_BUILD=go build
GO_INSTALL=go install
GO_FMT=gofmt -w
GO_LINT=golint
GO_VET=go vet
GO_IMPORTS=goimports -w
GO_TEST=go test

all: check structure runq gha2db db2influx sync

structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o structure cmd/structure/structure.go

runq: cmd/runq/runq.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o runq cmd/runq/runq.go

gha2db: cmd/gha2db/gha2db.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o gha2db cmd/gha2db/gha2db.go

db2influx: cmd/db2influx/db2influx.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o db2influx cmd/db2influx/db2influx.go

sync: cmd/sync/sync.go ${GO_LIB_FILES}
	 ${GO_ENV} ${GO_BUILD} -o sync cmd/sync/sync.go

fmt: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES}
	${GO_FMT} ${GO_LIB_FILES}
	${GO_FMT} ${GO_BIN_FILES}
	${GO_FMT} ${GO_TEST_FILES}
	${GO_FMT} ${GO_DBTEST_FILES}

lint: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES}
	${GO_LINT} ${GO_LIB_FILES}
	${GO_LINT} ${GO_BIN_FILES}
	${GO_LINT} ${GO_TEST_FILES}
	${GO_LINT} ${GO_DBTEST_FILES}

vet: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES}
	./govet.sh

imports: ${GO_BIN_FILES} ${GO_LIB_FILES} ${GO_TEST_FILES} ${GO_DBTEST_FILES}
	${GO_IMPORTS} ${GO_LIB_FILES}
	${GO_IMPORTS} ${GO_BIN_FILES}
	${GO_IMPORTS} ${GO_TEST_FILES}
	${GO_IMPORTS} ${GO_DBTEST_FILES}

test:
	${GO_TEST} ${GO_TEST_FILES}

dbtest:
	${GO_TEST} ${GO_DBTEST_FILES}

check: fmt lint imports vet

install: check structure runq gha2db db2influx sync
	${GO_INSTALL} ${GO_BIN_CMDS}

clean:
	rm -f structure runq gha2db db2influx sync

.PHONY: test
