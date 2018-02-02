-- Clear current repo groups (taken from merge of all other projects)
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
  org_login in (
    'kubernetes', 'kubernetes-client', 'kubernetes-incubator', 'kubernetes-helm'
  )
  or name in (
    'GoogleCloudPlatform/kubernetes', 'kubernetes' , 'kubernetes-client'
 )
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
  org_login in ('rkt' , 'coreos', 'rktproject')
  or name in ('rkt/Navigation_Drawer', 'rocket')
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
  org_login = 'vitess'
  or name in ('youtube/vitess', 'vitess')
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
