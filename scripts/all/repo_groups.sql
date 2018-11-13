-- Clear current repo groups (taken from merge of all other projects)
-- This script is executed every hour

update
  gha_repos
set
  repo_group = null,
  alias = null
;

-- Kubernetes
update
  gha_repos
set
  repo_group = 'Kubernetes',
  alias = 'Kubernetes'
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
  ) and name not in ('kubernetes/helm', 'kubernetes/deployment-manager', 'kubernetes/charts', 'kubernetes/application-dm-templates')
;

-- Prometheus
update
  gha_repos
set
  repo_group = 'Prometheus',
  alias = 'Prometheus'
where
  org_login = 'prometheus'
;

-- OpenTracing
update
  gha_repos
set
  repo_group = 'OpenTracing',
  alias = 'OpenTracing'
where
  org_login = 'opentracing'
;

-- Fluentd
update
  gha_repos
set
  repo_group = 'Fluentd',
  alias = 'Fluentd'
where
  org_login = 'fluent'
;

-- Linkerd
update
  gha_repos
set
  repo_group = 'Linkerd',
  alias = 'Linkerd'
where
  org_login = 'linkerd'
  or name = 'BuoyantIO/linkerd'
;

-- gRPC
update
  gha_repos
set
  repo_group = 'gRPC',
  alias = 'gRPC'
where
  org_login = 'grpc'
;

-- CoreDNS
update
  gha_repos
set
  repo_group = 'CoreDNS',
  alias = 'CoreDNS'
where
  org_login = 'coredns'
  or name = 'miekg/coredns'
;

-- containerd
update
  gha_repos
set
  repo_group = 'containerd',
  alias = 'containerd'
where
  org_login = 'containerd'
  or name = 'docker/containerd'
;

-- rkt
update
  gha_repos
set
  repo_group = 'rkt',
  alias = 'rkt'
where
  name != 'coreos/etcd'
  and (
    org_login in ('rkt' , 'coreos', 'rktproject')
    or name in ('rkt/Navigation_Drawer', 'rocket')
  )
;

-- CNI
update
  gha_repos
set
  repo_group = 'CNI',
  alias = 'CNI'
where
  org_login = 'containernetworking'
  or name = 'appc/cni'
;

-- Envoy
update
  gha_repos
set
  repo_group = 'Envoy',
  alias = 'Envoy'
where
  org_login = 'envoyproxy'
  or name = 'lyft/envoy'
;

-- Jaeger
update
  gha_repos
set
  repo_group = 'Jaeger',
  alias = 'Jaeger'
where
  org_login = 'jaegertracing'
  or name = 'uber/jaeger'
;

-- Notary
update
  gha_repos
set
  repo_group = 'Notary',
  alias = 'Notary'
where
  name in ('theupdateframework/notary', 'docker/notary')
;

-- TUF
update
  gha_repos
set
  repo_group = 'TUF',
  alias = 'TUF'
where
  org_login = 'theupdateframework'
  and name != 'theupdateframework/notary' 
;

-- Rook
update
  gha_repos
set
  repo_group = 'Rook',
  alias = 'Rook'
where
  org_login = 'rook'
;

-- Vitess
update
  gha_repos
set
  repo_group = 'Vitess',
  alias = 'Vitess'
where
  org_login = 'vitessio'
  or name in ('youtube/vitess', 'vitess')
;

-- NATS
update
  gha_repos
set
  repo_group = 'NATS',
  alias = 'NATS'
where
  org_login = 'nats-io'
  or name in ('apcera/gnatsd', 'gnatsd', 'apcera/nats', 'nats')
;

-- OPA
update
  gha_repos
set
  repo_group = 'OPA',
  alias = 'OPA'
where
  org_login = 'open-policy-agent'
  or name = 'open-policy-agent/opa'
;

-- SPIFFE
update
  gha_repos
set
  repo_group = 'SPIFFE',
  alias = 'SPIFFE'
where
  org_login = 'spiffe'
  and name != 'spiffe/spire'
;

-- SPIRE
update
  gha_repos
set
  repo_group = 'SPIRE',
  alias = 'SPIRE'
where
  name = 'spiffe/spire'
;

-- CloudEvents
update
  gha_repos
set
  repo_group = 'CloudEvents',
  alias = 'CloudEvents'
where
  org_login = 'cloudevents'
;

-- Telepresence
update
  gha_repos
set
  repo_group = 'Telepresence',
  alias = 'Telepresence'
where
  org_login in ('datawire', 'telepresenceio')
;

-- Helm
update
  gha_repos
set
  repo_group = 'Helm',
  alias = 'Helm'
where
  org_login in ('kubernetes-helm', 'kubernetes-charts', 'helm')
  or name in ('kubernetes/helm', 'kubernetes/deployment-manager', 'kubernetes/charts', 'kubernetes/application-dm-templates')
;

-- OpenMetrics
update
  gha_repos
set
  repo_group = 'OpenMetrics',
  alias = 'OpenMetrics'
where
  org_login = 'OpenObservability'
  or name in ('RichiH/OpenMetrics')
;

-- Harbor
update
  gha_repos
set
  repo_group = 'Harbor',
  alias = 'Harbor'
where
  org_login in ('goharbor')
  or name in ('vmware/harbor')
;

-- etcd
update
  gha_repos
set
  repo_group = 'etcd',
  alias = 'etcd'
where
  org_login in ('etcd-io', 'etcd')
  or name in ('coreos/etcd', 'etcd')
;

-- TiKV
update
  gha_repos
set
  repo_group = 'TiKV',
  alias = 'TiKV'
where
  org_login in ('tikv')
  or name in ('pingcap/tikv')
;

-- Cortex
update
  gha_repos
set
  repo_group = 'Cortex',
  alias = 'Cortex'
where
  org_login in ('cortexproject')
  or name in ('weaveworks/cortex')
;

-- Buildpacks
update
  gha_repos
set
  repo_group = 'Buildpacks',
  alias = 'Buildpacks'
where
  org_login in ('buildpack')
;

-- Falco
update
  gha_repos
set
  repo_group = 'Falco',
  alias = 'Falco'
where
  org_login in ('falcosecurity')
  or name in ('draios/falco')
;

-- Dragonfly
update
  gha_repos
set
  repo_group = 'Dragonfly',
  alias = 'Dragonfly'
where
  org_login in ('alibaba')
  and name in ('alibaba/Dragonfly')
;

-- CNCF
update
  gha_repos
set
  repo_group = 'CNCF',
  alias = 'CNCF'
where
  org_login in ('cncf', 'crosscloudci')
;

