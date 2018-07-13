FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install golang-1.9-go git psmisc jsonlint yamllint gcc -y
RUN apt-get install software-properties-common python-software-properties -y
RUN ln -s /usr/lib/go-1.9 /usr/lib/go
RUN add-apt-repository ppa:git-core/ppa -y
RUN apt-get update
RUN apt-get install git -y
RUN echo "GOROOT=/usr/lib/go; export GOROOT" >> /root/.bashrc
RUN echo "GOPATH=$HOME/go; export GOPATH" >> /root/.bashrc
RUN echo "PATH=$PATH:/usr/lib/go/bin:$HOME/go/bin; export PATH" >> /root/.bashrc
RUN /usr/lib/go/bin/go get -u github.com/golang/lint/golint
RUN /usr/lib/go/bin/go get golang.org/x/tools/cmd/goimports
RUN /usr/lib/go/bin/go get github.com/jgautheron/goconst/cmd/goconst
RUN /usr/lib/go/bin/go get github.com/jgautheron/usedexports
RUN /usr/lib/go/bin/go get github.com/kisielk/errcheck
RUN /usr/lib/go/bin/go get github.com/lib/pq
RUN /usr/lib/go/bin/go get golang.org/x/text/transform
RUN /usr/lib/go/bin/go get golang.org/x/text/unicode/norm
RUN /usr/lib/go/bin/go get gopkg.in/yaml.v2
RUN /usr/lib/go/bin/go get github.com/google/go-github/github
RUN /usr/lib/go/bin/go get golang.org/x/oauth2
RUN /usr/lib/go/bin/go get github.com/mattn/go-sqlite3
RUN cd /root/go/src && git clone https://github.com/cncf/devstats.git
RUN PATH=$PATH:/usr/lib/go/bin:$HOME/go/bin; export PATH && cd /root/go/src/devstats && make
RUN PATH=$PATH:/usr/lib/go/bin:$HOME/go/bin; export PATH && cd /root/go/src/devstats && make install

ENTRYPOINT /root/go/bin/gha2db ${START_TIME} ${END_TIME} ${ORG} ${REPO}
