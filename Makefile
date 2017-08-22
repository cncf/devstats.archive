GO_LIB_FILES=pg_conn.go error.go mgetc.go
GO_BIN_FILES=cmd/structure/structure.go
GO_BIN_CMDS=k8s.io/test-infra/gha2db/cmd/structure
GO_ENV=CGO_ENABLED=0
GO_FMT=gofmt -w
GO_LINT=golint

all: structure

structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 ${GO_ENV} go build -o structure cmd/structure/structure.go

fmt: ${GO_BIN_FILES} ${GO_LIB_FILES}
	${GO_FMT} ${GO_LIB_FILES}
	${GO_FMT} ${GO_BIN_FILES}

lint: ${GO_BIN_FILES} ${GO_LIB_FILES}
	${GO_LINT} ${GO_LIB_FILES}
	${GO_LINT} ${GO_BIN_FILES}

check: fmt lint

install: check structure
	go install ${GO_BIN_CMDS}

clean:
	rm -f structure
