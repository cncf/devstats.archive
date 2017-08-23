GO_LIB_FILES=pg_conn.go error.go mgetc.go map.go threads.go gha.go
GO_BIN_FILES=cmd/structure/structure.go cmd/runq/runq.go cmd/gha2db/gha2db.go
GO_BIN_CMDS=k8s.io/test-infra/gha2db/cmd/structure k8s.io/test-infra/gha2db/cmd/runq k8s.io/test-infra/gha2db/cmd/gha2db
GO_ENV=CGO_ENABLED=0
GO_FMT=gofmt -w
GO_LINT=golint

all: structure runq gha2db

structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 ${GO_ENV} go build -o structure cmd/structure/structure.go

runq: cmd/runq/runq.go ${GO_LIB_FILES}
	 ${GO_ENV} go build -o runq cmd/runq/runq.go

gha2db: cmd/gha2db/gha2db.go ${GO_LIB_FILES}
	 ${GO_ENV} go build -o gha2db cmd/gha2db/gha2db.go

fmt: ${GO_BIN_FILES} ${GO_LIB_FILES}
	${GO_FMT} ${GO_LIB_FILES}
	${GO_FMT} ${GO_BIN_FILES}

lint: ${GO_BIN_FILES} ${GO_LIB_FILES}
	${GO_LINT} ${GO_LIB_FILES}
	${GO_LINT} ${GO_BIN_FILES}

check: fmt lint

install: check structure runq gha2db
	go install ${GO_BIN_CMDS}

clean:
	rm -f structure runq gha2db
