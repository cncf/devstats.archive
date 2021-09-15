#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi
if [ -z "$2" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi

# To also sync 'gha2db' manually (if hours missing):
# PG_PASS=... GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/cli-runtime,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin' gha2db 2018-02-02 6 2019-08-01 0 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-charts,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired,prometheus,opentracing,fluent,linkerd,grpc,coredns,containerd,rkt,containernetworking,envoyproxy,jaegertracing,theupdateframework,rook,cncf,crosscloudci,vitessio,youtube,nats-io,apcera,open-policy-agent,spiffe,cloudevents,telepresenceio,goharbor,tikv,etcd-io,OpenObservability,cortexproject,buildpack,falcosecurity,dragonflyoss,virtual-kubelet,Virtual-Kubelet,kubeedge,brigadecore,cri-o,networkservicemesh,openebs,open-telemetry,thanos-io,fluxcd,in-toto,strimzi,kubevirt,longhorn,chubaofs,kedacore,servicemeshinterface,argoproj,argoproj-labs,volcano-sh,cni-genie,keptn,kudobuilder,cloud-custodian,dexidp,litmuschaos,artifacthub,parallaxsecond,bfenetworks,crossplane,kumahq,Kong/kuma,Kong/kuma-website,Kong/kuma-demo,Kong/kuma-gui,Kong/kumacut,Kong/docker-kuma,projectcontour,operator-framework,heptio/contour,chaos-mesh,serverlessworkflow,pingcap/chaos-mesh,cncf/wg-serverless-workflow,k3s-io,rancher/k3s,rancher/k3d,rancher/k3s-ansible,rancher/k3s-root,rancher/k3s-upgrade,rancher/k3s-selinux,rancher/terraform-k3s-aws-cluster,ibuildthecloud/k3s-root,ibuildthecloud/k3s-dev,ibuildthecloud/k3d,spotify/backstage,wayfair-tremor,tremor-rs,metal3-io,deislabs/porter,alibaba/openyurt,openservicemesh,getporter,keylime,backstage,schemahero,awslabs/cdk8s,cert-manager,jetstack/cert-manager,jetstack-experimental/cert-manager,openkruise,kruiseio,tinkerbell,packethost/tinkerbell,pravega,kyverno,gitopswg,piraeus,k8dash,athenz,kubeovn,curiefense,distribution,ingraind,redsift/ingraind,foniod,Comcast/kuberhealthy,kuberhealthy,k8gb-io,AbsaOSS/k8gb,AbsaOSS/ohmyglb,tricksterproxy,trickstercache,Comcast/trickster,emissary-ingress,datawire/ambassador,WasmEdge,second-state/SSVM,chaosblade-io,alibaba/v6d,alibaba/libvineyard,vmware-tanzu/antrea,antrea-io,fluid-cloudnative,cheyang/fluid,submariner-io,rancher/submariner,v6d-io,indeedeng/k8dash,indeedeng/k8dash-website,skooner-k8s,pixie-io,pixie-labs,layer5io,oam-dev,kube-vip,plunder-app/kube-vip,alibaba/kubedl,service-mesh-performance,deislabs/krustlet,krator-rs,oras-project,deislabs/oras,shizhMSFT/oras,wasmCloud,wascc,wascaruntime,waxosuit,deislabs/akri,metallb,danderson/metallb,google/metallb,karmada-io,alibaba/inclavare-containers,superedge'
# PG_PASS=... GHA2DB_PROJECT=kubernetes PG_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_REPOS='kubernetes/api,kubernetes/apiextensions-apiserver,kubernetes/apimachinery,kubernetes/apiserver,kubernetes/client-go,kubernetes/code-generator,kubernetes/kube-aggregator,kubernetes/metrics,kubernetes/sample-apiserver,kubernetes/sample-controller,kubernetes/helm,kubernetes/deployment-manager,kubernetes/charts,kubernetes/application-dm-templates,kubernetes/cli-runtime,kubernetes/csi-api,kubernetes/kube-proxy,kubernetes/kube-controller-manager,kubernetes/kube-scheduler,kubernetes/kubelet,kubernetes/sample-cli-plugin' gha2db 2018-03-27 15 2018-03-27 18 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-graveyard,kubernetes-incubator-retired,kubernetes-sig-testing,kubernetes-providers,kubernetes-addons,kubernetes-extensions,kubernetes-federation,kubernetes-security,kubernetes-sigs,kubernetes-sidecars,kubernetes-tools,kubernetes-test,kubernetes-retired'
# PG_PASS=... GHA2DB_PROJECT=fluentd PG_DB=fluentd GHA2DB_LOCAL=1 gha2db 2018-03-27 15 2018-03-27 18 'fluent'

# PG_PASS=... PG_DB=gha GHA2DB_DEBUG=1 ./devel/calculate_hours.sh '2017-12-20 11' '2017-12-20 13'
calc_metric events_h metrics/shared/events.sql "$1" "$2" h
periods="h d w m q y h24"
for period in $periods
do
  echo $period
  calc_metric multi_row_single_column metrics/shared/activity_repo_groups.sql "$1" "$2" "$period" multivalue
done
