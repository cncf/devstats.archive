FROM golang:1.11

RUN apt-get update -y \
  && apt-get upgrade -y \
  && apt-get install -y ca-certificates openssh-client git curl make \

WORKDIR /go/src/devstats

COPY . .

RUN make dockerinstall
