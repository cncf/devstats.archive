#!/bin/bash
kubectl delete secret pg-db
kubectl delete secret es-db
kubectl delete secret github-oauth
kubectl create secret generic pg-db --from-file=./k8s/secrets/PG_HOST.secret --from-file=./k8s/secrets/PG_PASS.secret --from-file=./k8s/secrets/PG_PORT.secret
kubectl create secret generic es-db --from-file=./k8s/secrets/GHA2DB_ES_URL.secret --from-file=./k8s/secrets/ES_PROTO.secret --from-file=./k8s/secrets/ES_HOST.secret --from-file=./k8s/secrets/ES_PORT.secret
kubectl create secret generic github-oauth --from-file=./k8s/secrets/GHA2DB_GITHUB_OAUTH.secret
