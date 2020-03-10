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
  org_login = 'fluent'
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
  and name != 'spiffe/spire'
;

-- SPIRE
update
  gha_repos
set
  repo_group = 'SPIRE'
where
  name = 'spiffe/spire'
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
  org_login in ('buildpack')
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
  org_login in ('fluxcd')
  or name in ('weaveworks/flux')
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

-- CNCF
update
  gha_repos
set
  repo_group = 'CNCF'
where
  org_login in ('cncf', 'crosscloudci', 'cdfoundation')
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
