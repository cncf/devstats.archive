GO_LIB_FILES=pg_conn.go error.go
GO_BIN_FILES=cmd/structure/structure.go
all: structure
structure: cmd/structure/structure.go ${GO_LIB_FILES}
	 CGO_ENABLED=0 go build -o structure cmd/structure/structure.go
fmt: ${GO_BIN_FILES} ${GO_LIB_FILE}
	gofmt -w pg_conn.go
	gofmt -w error.go
	gofmt -w cmd/structure/structure.go
lint: ${GO_BIN_FILES} ${GO_LIB_FILE}
	golint pg_conn.go
	golint error.go
	golint cmd/structure/structure.go
check: fmt lint
install: check structure
	go install k8s.io/test-infra/gha2db/cmd/structure
clean:
	rm -f structure
