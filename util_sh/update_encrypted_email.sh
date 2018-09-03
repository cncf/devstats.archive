#!/bin/bash
#GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/helm,kubernetes/deployment-manager,kubernetes/charts' GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 ./update_encrypted_email 2015-08-06 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-csi,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired' 2>>errors.txt | tee -a run.log || exit 2
#GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./update_encrypted_email 2015-01-01 0 2015-08-14 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 3
#GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./update_encrypted_email 2014-06-02 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi' 2>>errors.txt | tee -a run.log || exit 4
#GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now 'prometheus' 2>>errors.txt | tee -a run.log || exit 2
#GHA2DB_PROJECT=prometheus PG_DB=prometheus GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./update_encrypted_email 2014-01-06 0 2014-12-31 23 'prometheus/prometheus' 2>>errors.txt | tee -a run.log || exit 3
#GHA2DB_PROJECT=opentracing PG_DB=opentracing GHA2DB_LOCAL=1 ./update_encrypted_email 2015-11-26 0 today now 'opentracing' 2>>errors.txt | tee -a run.log || exit 2
#GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now 'fluent' 2>>errors.txt | tee -a run.log || exit 2
#GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-01-02 0 2014-12-31 23 'fluent' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 ./update_encrypted_email 2017-01-23 0 today now 'linkerd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=linkerd PG_DB=linkerd GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./update_encrypted_email 2016-01-13 0 2017-01-24 0 'BuoyantIO/linkerd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=grpc PG_DB=grpc GHA2DB_LOCAL=1 ./update_encrypted_email 2015-02-23 0 today now 'grpc' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=coredns PG_DB=coredns GHA2DB_LOCAL=1 ./update_encrypted_email 2016-03-18 0 today now 'miekg/coredns,coredns' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=containerd PG_DB=containerd GHA2DB_LOCAL=1 ./update_encrypted_email 2015-12-17 0 today now 'containerd,docker/containerd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 ./update_encrypted_email 2017-04-04 0 today now 'rkt' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./update_encrypted_email 2015-01-01 0 2017-04-07 0 'coreos/rkt,coreos/rocket,rktproject/rkt' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=rkt PG_DB=rkt GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-11-26 0 2014-12-31 23 'rocket' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=cni PG_DB=cni GHA2DB_LOCAL=1 ./update_encrypted_email 2016-05-04 0 today now 'containernetworking' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=cni PG_DB=cni GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./update_encrypted_email 2015-04-04 0 2016-05-05 0 'appc/cni' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=envoy PG_DB=envoy GHA2DB_LOCAL=1 ./update_encrypted_email 2016-09-13 0 today now 'envoyproxy,lyft/envoy' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=jaeger PG_DB=jaeger GHA2DB_LOCAL=1 ./update_encrypted_email 2016-11-01 0 today now 'jaegertracing,uber/jaeger' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=notary PG_DB=notary GHA2DB_LOCAL=1 ./update_encrypted_email 2015-06-22 0 today now 'theupdateframework,docker' 'notary' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_EXCLUDE_REPOS='theupdateframework/notary' GHA2DB_PROJECT=tuf PG_DB=tuf GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now 'theupdateframework' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=tuf PG_DB=tuf GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-01-02 0 2014-12-31 23 'theupdateframework,tuf' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=rook PG_DB=rook GHA2DB_LOCAL=1 ./update_encrypted_email 2016-11-07 0 today now 'rook' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=vitess PG_DB=vitess GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now 'vitessio,youtube/vitess' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=vitess PG_DB=vitess GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-01-02 0 2014-12-31 23 'vitessio,youtube/vitess' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-01-02 0 2014-03-02 16 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./update_encrypted_email 2014-03-02 18 2014-12-31 23 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=opa PG_DB=opa GHA2DB_LOCAL=1 ./update_encrypted_email 2015-12-27 0 today now 'open-policy-agent' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_EXCLUDE_REPOS='spiffe/spire' GHA2DB_PROJECT=spiffe PG_DB=spiffe GHA2DB_LOCAL=1 ./update_encrypted_email 2017-08-23 0 today now 'spiffe' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=spire PG_DB=spire GHA2DB_LOCAL=1 ./update_encrypted_email 2017-09-28 0 today now 'spiffe' 'spire' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=opencontainers PG_DB=opencontainers GHA2DB_LOCAL=1 ./update_encrypted_email 2015-06-22 0 today now 'opencontainers' 'image-tools,image-spec,runtime-tools,ocitools,runtime-spec,specs,runc' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=cloudevents PG_DB=cloudevents GHA2DB_LOCAL=1 ./update_encrypted_email 2017-12-09 0 today now 'cloudevents,openeventing' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=telepresence PG_DB=telepresence GHA2DB_LOCAL=1 ./update_encrypted_email 2017-03-02 0 today now 'telepresenceio,datawire/telepresence' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=helm PG_DB=helm GHA2DB_LOCAL=1 ./update_encrypted_email 2015-10-06 0 today now 'helm,kubernetes-helm,kubernetes-charts,kubernetes/helm,kubernetes/charts,kubernetes/deployment-manager' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=openmetrics PG_DB=openmetrics GHA2DB_LOCAL=1 ./update_encrypted_email 2017-06-22 0 today now RichiH OpenMetrics 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=harbor PG_DB=harbor GHA2DB_LOCAL=1 ./update_encrypted_email 2016-03-02 0 today now "goharbor,vmware/harbor" 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=etcd PG_DB=etcd GHA2DB_LOCAL=1 ./update_encrypted_email 2015-01-01 0 today now "coreos/etcd,etcd" 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=etcd PG_DB=etcd GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./update_encrypted_email 2014-01-02 0 2014-12-31 23 'etcd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=tikv PG_DB=tikv GHA2DB_LOCAL=1 ./update_encrypted_email 2016-04-01 0 today now "pingcap/tikv,tikv" 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=cncf PG_DB=cncf GHA2DB_LOCAL=1 ./update_encrypted_email 2015-10-01 18 today now 'cncf,crosscloudci' 2>>errors.txt | tee -a run.log || exit 2
