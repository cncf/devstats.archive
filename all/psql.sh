#!/bin/bash
# MERGE_MODE=1 (use merge DBs mode instead of generating data via 'gha2db')
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql allprj -c "create extension if not exists pgcrypto" || exit 2
if [ -z "$MERGE_MODE" ]
then
  exclude="kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin"
  args="kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-csi,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired,GoogleCloudPlatform/kubernetes"
  args="${args},prometheus,opentracing,fluent,linkerd,BuoyantIO/linkerd,grpc,miekg/coredns,coredns,containerd,docker/containerd,rkt,coreos/rkt,coreos/rocket,rktproject/rkt,containernetworking,appc/cni,envoyproxy,lyft/envoy,jaegertracing,uber/jaeger,theupdateframework,docker/notary,rook,vitessio,youtube/vitess,nats-io,apcera/nats,apcera/gnatsd"
  args="${args},open-policy-agent,spiffe,cloudevents,openeventing,telepresenceio,datawire/telepresence,helm,kubernetes-helm,kubernetes-charts,kubernetes/helm,kubernetes/charts,kubernetes/deployment-manager,kubernetes/application-dm-templates,OpenObservability,RichiH/OpenMetrics,goharbor,vmware/harbor,coreos/etcd,etcd,etcd-io,pingcap/tikv,tikv,buildpacks"
  args="${args},cortexproject,weaveworks/cortex,weaveworks/prism,weaveworks/frankenstein,buildpack,falcosecurity,draios/falco,dragonflyoss,alibaba/Dragonfly,virtual-kubelet,Virtual-Kubelet,kubeedge,brigadecore,Azure/brigade,kubernetes-incubator/ocid,kubernetes-incubator/cri-o,kubernetes-sigs/cri-o,cri-o,networkservicemesh,NetworkServiceMesh,ligato/networkservicemesh"
  args="${args},openebs,open-telemetry,thanos-io,improbable-eng/promlts,improbable-eng/thanos,fluxcd,weaveworks/flux,in-toto,strimzi,EnMasseProject/barnabas,ppatierno/barnabas,ppatierno/kaas,kubevirt,cncf,crosscloudci,cdfoundation,longhorn,chubaofs,kedacore,containerfs/containerfs.github.io,containerfilesystem/cfs,containerfilesystem/doc-zh"
  args="${args},tomkerkhove/sample-dotnet-queue-worker,tomkerkhove/sample-dotnet-queue-worker-servicebus-queue,tomkerkhove/sample-dotnet-worker-servicebus-queue,rancher/longhorn,deislabs/smi-spec,deislabs/smi-sdk-go,deislabs/smi-metrics,deislabs/smi-adapter-istio,deislabs/smi-spec.io,servicemeshinterface,argoproj,volcano-sh,cni-genie,keptn,kudobuilder,kumahq"
  args="${args},Huawei-PaaS/CNI-Genie,patras-sdk/kubebuilder-maestro,patras-sdk/maestro,maestrosdk/maestro,maestrosdk/frameworks,cloud-custodian,capitalone/cloud-custodian,dexidp,coreos/dex,litmuschaos,artifacthub,Kong/kuma,Kong/kuma-website,Kong/kuma-demo,Kong/kuma-gui,Kong/kumacut,Kong/docker-kuma,parallaxsecond,docker/pasl,bfenetworks,baidu/bfe,crossplane,crossplaneio,cdk8s-team"
  args="${args},projectcontour,operator-framework,heptio/contour,chaos-mesh,serverlessworkflow,pingcap/chaos-mesh,cncf/wg-serverless-workflow,rancher/k3s,rancher/k3d,rancher/k3s-ansible,rancher/k3s-root,rancher/k3s-upgrade,rancher/k3s-selinux,rancher/terraform-k3s-aws-cluster,ibuildthecloud/k3s-root,ibuildthecloud/k3s-dev,ibuildthecloud/k3d,skooner-k8s,antrea-io"
  args="${args},spotify/backstage,wayfair-tremor,metal3-io,deislabs/porter,alibaba/openyurt,awslabs/cdk8s,jetstack/cert-manager,jetstack-experimental/cert-manager,packethost/tinkerbell,openservicemesh,getporter,keylime,backstage,schemahero,openkruise,kruiseio,tinkerbell,pravega,kyverno,cert-manager,k3s-io,gitops-working-group,piraeusdatastore,indeedeng/k8dash,indeedeng/k8dash-website"
  args="${args},yahoo/athenz,alauda/kube-ovn,curiefense,distribution,kubeovn,AthenZ,openyurtio,foniod,ingraind,redsift/ingraind,Comcast/kuberhealthy,k8gb-io,AbsaOSS/k8gb,AbsaOSS/ohmyglb,tricksterproxy,trickstercache,Comcast/trickster,emissary-ingress,datawire/ambassador,kuberhealthy,WasmEdge,second-state/SSVM,chaosblade-io,alibaba/v6d,alibaba/libvineyard,vmware-tanzu/antrea,v6d-io"
  args="${args},fluid-cloudnative,cheyang/fluid,submariner-io,rancher/submariner,argoproj-labs"
  GHA2DB_EXCLUDE_REPOS=$exclude GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 gha2db 2015-01-01 0 today now "$args" 2>>errors.txt | tee -a run.log || exit 3
  args="GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client,kubernetes-csi,prometheus/prometheus,fluent,rocket,theupdateframework,tuf,vitessio,youtube/vitess,nats-io,apcera/nats,apcera/gnatsd,etcd"
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 gha2db 2014-01-02 0 2014-12-31 23 "$args" 2>>errors.txt | tee -a run.log || exit 4
else
  GHA2DB_INPUT_DBS="gha,prometheus,opentracing,fluentd,linkerd,grpc,coredns,containerd,cni,envoy,jaeger,notary,tuf,rook,vitess,nats,cncf,opa,spiffe,spire,cloudevents,telepresence,helm,openmetrics,harbor,etcd,tikv,cortex,buildpacks,falco,dragonfly,virtualkubelet,kubeedge,brigade,crio,networkservicemesh,openebs,opentelemetry,thanos,flux,intoto,strimzi,kubevirt,longhorn,chubaofs,kedacore,servicemeshinterface,argoproj,volcano,cnigenie,keptn,kudo,cloudcustodian,dex,litmuschaos,artifacthub,kuma,parsec,bfe,crossplane,contour,operatorframework,chaosmesh,serverlessworkflow,k3s,backstage,tremor,metal3,porter,openyurt,openservicemesh,keylime,schemahero,cdk8s,certmanager,openkruise,tinkerbell,pravega,kyverno,gitopswg,piraeus,k8dash,athenz,kubeovn,curiefense,distribution,ingraind,kuberhealthy,k8gb,trickster,emissaryingress,wasmedge,chaosblade,vineyard,antrea,fluid,submariner" GHA2DB_OUTPUT_DB="allprj" merge_dbs || exit 2
fi
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=all PG_DB=allprj ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=all PG_DB=allprj ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_VARS="projects_health_partial_html" vars || exit 8
./devel/ro_user_grants.sh allprj || exit 10
./devel/psql_user_grants.sh devstats_team allprj || exit 11
