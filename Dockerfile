FROM golang:1.11 AS builder
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y ca-certificates openssh-client postgresql-client git curl make
WORKDIR /go/src/devstats
ADD devstats.tar .
RUN make dockerinstall
RUN make clean
FROM alpine
RUN apk add git bash postgresql-client xz curl
COPY --from=builder /etc/gha2db /etc/gha2db
COPY --from=builder /go/src/devstats /go/src/devstats
COPY --from=builder /devstats-minimal/* /usr/bin/
WORKDIR /go/src/devstats
