FROM golang:1.11

RUN apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y ca-certificates openssh-client git curl make \

RUN go get github.com/golang/dep/cmd/dep \
  && go get golang.org/x/lint/golint \
  && go get golang.org/x/tools/cmd/goimports \
  && go get github.com/jgautheron/goconst/cmd/goconst \
  && go get github.com/jgautheron/usedexports \
  && go get github.com/kisielk/errcheck

WORKDIR /go/src/devstats

COPY . .

RUN make test install
