-- Clear current repo groups (taken from merge of all other projects)
-- This script is executed every hour

update
  gha_repos
set
  repo_group = null
;

-- Kubernetes
update
  gha_repos
set
  repo_group = 'Kubernetes'
where
  (
    org_login in (
      'kubernetes', 'kubernetes-client', 'kubernetes-incubator', 'kubernetes-csi',
      'kubernetes-graveyard', 'kubernetes-incubator-retired', 'kubernetes-sig-testing',
      'kubernetes-providers', 'kubernetes-addons', 'kubernetes-retired',
      'kubernetes-extensions', 'kubernetes-federation', 'kubernetes-security',
      'kubernetes-sidecars', 'kubernetes-tools', 'kubernetes-test', 'kubernetes-sigs'
    )
    or name in (
      'GoogleCloudPlatform/kubernetes', 'kubernetes' , 'kubernetes-client'
    )
  ) and name not in (
    'kubernetes/helm', 'kubernetes/deployment-manager', 'kubernetes/charts',
    'kubernetes/application-dm-templates', 'kubernetes-sigs/cri-o',
    'kubernetes-incubator/ocid', 'kubernetes-incubator/cri-o'
  )
;

-- Prometheus
update
  gha_repos
set
  repo_group = 'Prometheus'
where
  org_login = 'prometheus'
;

-- OpenTracing
update
  gha_repos
set
  repo_group = 'OpenTracing'
where
  org_login = 'opentracing'
;

-- Fluentd
update
  gha_repos
set
  repo_group = 'Fluentd'
where
  name ~ '(?i)^(fluent|fluent-plugins-nursery\/.*fluent.*|.+\/fluentd?-plugin-.+|baritolog\/barito-fluent-plugin|blacknight95\/aws-fluent-plugin-kinesis|sumologic\/fluentd-kubernetes-sumologic|sumologic\/fluentd-output-sumologic|wallynegima\/scenario-manager-plugin|aliyun\/aliyun-odps-fluentd-plugin|awslabs\/aws-fluent-plugin-kinesis|campanja\/fluent-output-router|grafana\/loki\/|jdoconnor\/fluentd_https_out|newrelic\/newrelic-fluentd-output|roma42427\/filter_wms_auth|scalyr\/scalyr-fluentd|sebryu\/fluent_plugin_in_websocket|tagomoris\/fluent-helper-plugin-spec|y-ken\/fluent-mixin-rewrite-tag-name|y-ken\/fluent-mixin-type-converter)$'
;

-- Linkerd
update
  gha_repos
set
  repo_group = 'Linkerd'
where
  org_login = 'linkerd'
  or name = 'BuoyantIO/linkerd'
;

-- gRPC
update
  gha_repos
set
  repo_group = 'gRPC'
where
  org_login = 'grpc'
;

-- CoreDNS
update
  gha_repos
set
  repo_group = 'CoreDNS'
where
  org_login = 'coredns'
  or name = 'miekg/coredns'
;

-- containerd
update
  gha_repos
set
  repo_group = 'containerd'
where
  org_login = 'containerd'
  or name = 'docker/containerd'
;

-- rkt
update
  gha_repos
set
  repo_group = 'rkt'
where
  name != 'coreos/etcd'
  and (
    org_login in ('rkt' , 'coreos', 'rktproject')
    or name in ('rkt/Navigation_Drawer', 'rocket')
    or name like 'rkt/%'
  )
;

-- CNI
update
  gha_repos
set
  repo_group = 'CNI'
where
  org_login = 'containernetworking'
  or name = 'appc/cni'
;

-- Envoy
update
  gha_repos
set
  repo_group = 'Envoy'
where
  org_login = 'envoyproxy'
  or name = 'lyft/envoy'
;

-- Jaeger
update
  gha_repos
set
  repo_group = 'Jaeger'
where
  org_login = 'jaegertracing'
  or name = 'uber/jaeger'
;

-- Notary
update
  gha_repos
set
  repo_group = 'Notary'
where
  name in ('theupdateframework/notary', 'docker/notary')
;

-- TUF
update
  gha_repos
set
  repo_group = 'TUF'
where
  org_login = 'theupdateframework'
  and name != 'theupdateframework/notary' 
;

-- Rook
update
  gha_repos
set
  repo_group = 'Rook'
where
  org_login = 'rook'
;

-- Vitess
update
  gha_repos
set
  repo_group = 'Vitess'
where
  org_login = 'vitessio'
  or name in ('youtube/vitess', 'vitess')
;

-- NATS
update
  gha_repos
set
  repo_group = 'NATS'
where
  org_login = 'nats-io'
  or name in ('apcera/gnatsd', 'gnatsd', 'apcera/nats', 'nats')
;

-- OPA
update
  gha_repos
set
  repo_group = 'OPA'
where
  org_login = 'open-policy-agent'
  or name = 'open-policy-agent/opa'
;

-- SPIFFE
update
  gha_repos
set
  repo_group = 'SPIFFE'
where
  org_login = 'spiffe'
  and name not in (
    'spiffe/spire',
    'spiffe/spire-k8s',
    'spiffe/spire-test',
    'spiffe/spire-tutorials',
    'spiffe/spire-examples',
    'spiffe/spire-circleci-test'
  )
;

-- SPIRE
update
  gha_repos
set
  repo_group = 'SPIRE'
where
  name ~ '(?i)^(spiffe\/spire.*)$'
;

-- CloudEvents
update
  gha_repos
set
  repo_group = 'CloudEvents'
where
  org_login in ('cloudevents', 'openeventing')
;

-- Telepresence
update
  gha_repos
set
  repo_group = 'Telepresence'
where
  org_login in ('datawire', 'telepresenceio')
;

-- Helm
update
  gha_repos
set
  repo_group = 'Helm'
where
  org_login in ('kubernetes-helm', 'kubernetes-charts', 'helm')
  or name in ('kubernetes/helm', 'kubernetes/deployment-manager', 'kubernetes/charts', 'kubernetes/application-dm-templates')
;

-- OpenMetrics
update
  gha_repos
set
  repo_group = 'OpenMetrics'
where
  org_login = 'OpenObservability'
  or name in ('RichiH/OpenMetrics')
;

-- Harbor
update
  gha_repos
set
  repo_group = 'Harbor'
where
  org_login in ('goharbor')
  or name in ('vmware/harbor')
;

-- etcd
update
  gha_repos
set
  repo_group = 'etcd'
where
  org_login in ('etcd-io', 'etcd')
  or name in ('coreos/etcd', 'etcd')
  or name like 'etcd/%'
;

-- TiKV
update
  gha_repos
set
  repo_group = 'TiKV'
where
  org_login in ('tikv')
  or name in ('pingcap/tikv')
;

-- Cortex
update
  gha_repos
set
  repo_group = 'Cortex'
where
  org_login in ('cortexproject')
  or name in (
    'weaveworks/cortex',
    'weaveworks/frankenstein',
    'weaveworks/prism'
  )
;

-- Buildpacks
update
  gha_repos
set
  repo_group = 'Buildpacks'
where
  org_login in ('buildpack', 'buildpacks')
;

-- Falco
update
  gha_repos
set
  repo_group = 'Falco'
where
  org_login in ('falcosecurity')
  or name in ('draios/falco')
;

-- Dragonfly
update
  gha_repos
set
  repo_group = 'Dragonfly'
where
  org_login in ('dragonflyoss')
  or name in ('alibaba/Dragonfly')
;

-- Virtual Kubelet
update
  gha_repos
set
  repo_group = 'Virtual Kubelet'
where
  org_login in ('virtual-kubelet', 'Virtual-Kubelet')
;

-- KubeEdge
update
  gha_repos
set
  repo_group = 'KubeEdge'
where
  org_login in ('kubeedge')
;

-- Brigade
update
  gha_repos
set
  repo_group = 'Brigade'
where
  org_login in ('brigadecore')
  or name in ('Azure/brigade')
;

-- CRI-O
update
  gha_repos
set
  repo_group = 'CRI-O'
where
  org_login in ('cri-o')
  or name in (
    'kubernetes-sigs/cri-o',
    'kubernetes-incubator/ocid',
    'kubernetes-incubator/cri-o'
  )
;

-- Network Service Mesh
update
  gha_repos
set
  repo_group = 'Network Service Mesh'
where
  lower(org_login) in ('networkservicemesh')
  or name in (
    'ligato/networkservicemesh'
  )
;

-- OpenEBS
update
  gha_repos
set
  repo_group = 'OpenEBS'
where
  org_login in ('openebs')
  and name not in (
    'openebs/test-storage',
    'openebs/litmus'
  )
;

-- OpenTelemetry
update
  gha_repos
set
  repo_group = 'OpenTelemetry'
where
  org_login in ('open-telemetry')
;

-- Thanos
update
  gha_repos
set
  repo_group = 'Thanos'
where
  org_login in ('thanos-io')
  or name in (
    'improbable-eng/promlts',
    'improbable-eng/thanos'
  )
;

-- Flux
update
  gha_repos
set
  repo_group = 'Flux'
where
  name not in ('fluxcd/gitops-working-group')
  and (
    org_login in ('fluxcd')
    or name in ('weaveworks/flux')
  )
;


-- in-toto
update
  gha_repos
set
  repo_group = 'in-toto'
where
  org_login in ('in-toto')
;

-- Strimzi
update
  gha_repos
set
  repo_group = 'Strimzi'
where
  org_login in ('strimzi')
  or name in ('EnMasseProject/barnabas', 'ppatierno/barnabas', 'ppatierno/kaas')
;

-- KubeVirt
update
  gha_repos
set
  repo_group = 'KubeVirt'
where
  org_login in ('kubevirt')
;

-- Longhorn
update
  gha_repos
set
  repo_group = 'Longhorn'
where
  org_login in ('longhorn')
  or name in ('rancher/longhorn')
;

-- ChubaoFS
update
  gha_repos
set
  repo_group = 'ChubaoFS'
where
  org_login in ('chubaofs')
  or name in (
    'containerfs/containerfs.github.io', 'containerfilesystem/cfs', 'containerfilesystem/doc-zh'
  )
;

-- KEDA
update
  gha_repos
set
  repo_group = 'KEDA'
where
  org_login in ('kedacore')
  or name in (
    'tomkerkhove/sample-dotnet-queue-worker',
    'tomkerkhove/sample-dotnet-queue-worker-servicebus-queue',
    'tomkerkhove/sample-dotnet-worker-servicebus-queue'
  )
;

-- SMI
update
  gha_repos
set
  repo_group = 'SMI'
where
  org_login in ('servicemeshinterface')
  or name in (
    'deislabs/smi-spec',
    'deislabs/smi-sdk-go',
    'deislabs/smi-metrics',
    'deislabs/smi-adapter-istio',
    'deislabs/smi-spec.io'
  )
;

-- Argo
update
  gha_repos
set
  repo_group = 'Argo'
where
  org_login in ('argoproj')
;

-- Volcano
update
  gha_repos
set
  repo_group = 'Volcano'
where
  org_login in ('volcano-sh')
;

-- CNI-Genie
update
  gha_repos
set
  repo_group = 'CNI-Genie'
where
  org_login in ('cni-genie')
  or name in (
    'Huawei-PaaS/CNI-Genie'
  )
;

-- Keptn
update
  gha_repos
set
  repo_group = 'Keptn'
where
  org_login in ('keptn')
;

-- Kudo
update
  gha_repos
set
  repo_group = 'Kudo'
where
  org_login in ('kudobuilder')
  or name in (
    'patras-sdk/kubebuilder-maestro',
    'patras-sdk/maestro',
    'maestrosdk/maestro',
    'maestrosdk/frameworks'
  )
;

-- Cloud Custodian
update
  gha_repos
set
  repo_group = 'Cloud Custodian'
where
  org_login in ('cloud-custodian')
  or name in (
    'capitalone/cloud-custodian'
  )
;

-- Dex
update
  gha_repos
set
  repo_group = 'Dex'
where
  org_login in ('dexidp')
  or name in (
    'coreos/dex'
  )
;

-- LitmusChaos
update
  gha_repos
set
  repo_group = 'LitmusChaos'
where
  org_login in ('litmuschaos')
  or name in (
    'openebs/test-storage',
    'openebs/litmus'
  )
;

-- Artifact Hub
update
  gha_repos
set
  repo_group = 'Artifact Hub'
where
  org_login in ('artifacthub')
  or name in (
    'cncf/hub'
  )
;

-- Kuma
update
  gha_repos
set
  repo_group = 'Kuma'
where
  org_login in ('kumahq')
  or name in (
    'Kong/kuma',
    'Kong/kuma-website',
    'Kong/kuma-demo',
    'Kong/kuma-gui',
    'Kong/kumacut',
    'Kong/docker-kuma'
  )
;

-- PARSEC
update
  gha_repos
set
  repo_group = 'PARSEC'
where
  org_login in ('parallaxsecond')
  or name in (
    'docker/pasl'
  )
;

-- BFE
update
  gha_repos
set
  repo_group = 'BFE'
where
  org_login in ('bfenetworks')
  or name in (
    'baidu/bfe'
  )
;

-- Crossplane
update
  gha_repos
set
  repo_group = 'Crossplane'
where
  org_login in (
    'crossplane',
    'crossplaneio'
  )
;

-- Contour
update
  gha_repos
set
  repo_group = 'Contour'
where
  org_login in ('projectcontour')
  or name in ('heptio/contour')
;

-- Operator Framework
update
  gha_repos
set
  repo_group = 'Operator Framework'
where
  org_login in ('operator-framework')
;

-- Chaos Mesh
update
  gha_repos
set
  repo_group = 'Chaos Mesh'
where
  org_login in ('chaos-mesh')
  or name in ('pingcap/chaos-mesh')
;

-- Serverless Workflow
update
  gha_repos
set
  repo_group = 'Serverless Workflow'
where
  org_login in ('serverlessworkflow')
  or name in ('cncf/wg-serverless-workflow')
;

-- K3s
update
  gha_repos
set
  repo_group = 'K3s'
where
  org_login in ('k3s-io')
  or name ~ '(?i)^(ibuildthecloud|rancher)\/.*k3(s|d).*$'
;

-- Backstage
update
  gha_repos
set
  repo_group = 'Backstage'
where
  org_login in ('backstage')
  or name in ('spotify/backstage')
;

-- Tremor
update
  gha_repos
set
  repo_group = 'Tremor'
where
  org_login in ('wayfair-tremor', 'tremor-rs')
;

-- Metal³
update
  gha_repos
set
  repo_group = 'Metal³'
where
  org_login in ('metal3-io')
;

-- Porter
update
  gha_repos
set
  repo_group = 'Porter'
where
  name in ('deislabs/porter')
  or org_login in ('getporter')
;

-- OpenYurt
update
  gha_repos
set
  repo_group = 'OpenYurt'
where
  name in ('alibaba/openyurt')
  or org_login in ('openyurtio')
;

-- Open Service Mesh
update
  gha_repos
set
  repo_group = 'Open Service Mesh'
where
  org_login in ('openservicemesh')
;

-- Keylime
update
  gha_repos
set
  repo_group = 'Keylime'
where
  org_login in ('keylime')
  or name in ('mit-ll/python-keylime', 'mit-ll/keylime')
;

-- SchemaHero
update
  gha_repos
set
  repo_group = 'SchemaHero'
where
  org_login in ('schemahero')
;

-- Cloud Deployment Kit for Kubernetes
-- CDK8s
update
  gha_repos
set
  repo_group = 'Cloud Deployment Kit for Kubernetes'
where
  org_login in ('cdk8s-team')
  or name in ('awslabs/cdk8s')
;

-- cert-manager
update
  gha_repos
set
  repo_group = 'cert-manager'
where
  org_login in ('cert-manager')
  or name in ('jetstack/cert-manager', 'jetstack-experimental/cert-manager')
;

-- OpenKruise
update
  gha_repos
set
  repo_group = 'OpenKruise'
where
  org_login in ('openkruise', 'kruiseio')
;

-- Tinkerbell
update
  gha_repos
set
  repo_group = 'Tinkerbell'
where
  org_login in ('tinkerbell')
  or name in ('packethost/tinkerbell')
;

-- Pravega
update
  gha_repos
set
  repo_group = 'Pravega'
where
  org_login in ('pravega')
;

-- Kyverno
update
  gha_repos
set
  repo_group = 'Kyverno'
where
  org_login in ('kyverno')
  or name in ('nirmata/kyverno')
;

-- GitOps WG
update
  gha_repos
set
  repo_group = 'GitOps WG'
where
  org_login in ('gitops-working-group')
  or name in ('fluxcd/gitops-working-group')
;

-- Piraeus-Datastore
update
  gha_repos
set
  repo_group = 'Piraeus-Datastore'
where
  org_login in ('piraeusdatastore')
;

-- k8dash
update
  gha_repos
set
  repo_group = 'k8dash'
where
  name in (
    'indeedeng/k8dash',
    'indeedeng/k8dash-website',
    'herbrandson/k8dash'
  )
;

-- Athenz
update
  gha_repos
set
  repo_group = 'Athenz'
where
  org_login in ('AthenZ')
  or name ~ '(?i)^(AthenZ\/.*|yahoo\/.*athenz.*)$'
;

-- Kube-OVN
update
  gha_repos
set
  repo_group = 'Kube-OVN'
where
  org_login in ('kubeovn')
  or name in ('alauda/kube-ovn')
;

-- Curiefense
update
  gha_repos
set
  repo_group = 'Curiefense'
where
  org_login in ('curiefense')
;

-- Distribution
update
  gha_repos
set
  repo_group = 'Distribution'
where
  org_login in ('distribution')
  or name in ('docker/distribution')
;

-- ingraind
update
  gha_repos
set
  repo_group = 'ingraind'
where
  org_login in ('ingraind', 'foniod')
  or name in ('redsift/ingraind')
;

-- Kuberhealthy
update
  gha_repos
set
  repo_group = 'Kuberhealthy'
where
  name in ('Comcast/kuberhealthy')
;

-- K8GB
update
  gha_repos
set
  repo_group = 'K8GB'
where
  name in ('AbsaOSS/k8gb', 'AbsaOSS/ohmyglb')
;

-- Trickster
update
  gha_repos
set
  repo_group = 'Trickster'
where
  org_login in ('tricksterproxy')
  or name in ('Comcast/trickster')
;

-- CNCF
update
  gha_repos
set
  repo_group = 'CNCF'
where
  org_login in ('cncf', 'crosscloudci', 'cdfoundation')
  and name not in (
    'cncf/hub',
    'cncf/wg-serverless-workflow'
  )
;

with repo_latest as (
  select sub.repo_id,
    sub.repo_name
  from (
    select repo_id,
      dup_repo_name as repo_name,
      row_number() over (partition by repo_id order by created_at desc, id desc) as row_num
    from
      gha_events
  ) sub
  where
    sub.row_num = 1
)
update
  gha_repos r
set
  alias = (
    select rl.repo_name
    from
      repo_latest rl
    where
      rl.repo_id = r.id
  )
where
  r.name like '%_/_%'
  and r.name not like '%/%/%'
;

-- Stats
select
  repo_group,
  count(*) as number_of_repos
from
  gha_repos
where
  repo_group is not null
group by
  repo_group
order by
  number_of_repos desc,
  repo_group asc;
