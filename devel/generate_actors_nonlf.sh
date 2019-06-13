#!/bin/bash
# Run inside 'devstats' image pod shell:
if ( [ -z "${PG_PASS}" ] || [ -z "${PG_HOS}T" ] )
then
  echo "$0: you need to set PG_HOST=... and PG_PASS=... to run this script"
  exit 1
fi
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA gha < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA prometheus < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA opentracing < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA fluentd < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA linkerd < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA grpc < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA coredns < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA containerd < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA rkt < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA cni < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA envoy < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA jaeger < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA notary < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA tuf < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA rook < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA vitess < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA nats < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA opa < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA spiffe < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA spire < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA cloudevents < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA telepresence < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA helm < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA harbor < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA openmetrics < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA etcd < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA tikv < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA cortex < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA buildpacks < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA falco < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA dragonfly < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA virtualkubelet < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA kubeedge < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA brigade < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA crio < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA networkservicemesh < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA openebs < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA opentelemetry < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA cncf < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA allprj < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA spinnaker < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA tekton < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA jenkins < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA jenkinsx < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA allcdf < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphql < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphqljs < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphiql < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA expressgraphql < ./util_sql/actors.sql
PGPASSWORD="${PG_PASS}" psql -h "${PG_HOST}" -U gha_admin -tA graphqlspec < ./util_sql/actors.sql
