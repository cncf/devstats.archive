#!/bin/bash
dep ensure -add golang.org/x/lint/golint golang.org/x/tools/cmd/goimports github.com/jgautheron/goconst/cmd/goconst github.com/jgautheron/usedexports github.com/kisielk/errcheck
