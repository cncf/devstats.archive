#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

GHA2DB_PROJECTS_YAML="cdf/projects.yaml" ONLY="spinnaker tekton jenkinsx" ./devel/all_affs.sh || exit 2
GHA2DB_PROJECTS_YAML="cdf_projects.yaml" GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats

GHA2DB_PROJECTS_YAML="cdf/projects.yaml" ONLY="jenkins allcdf" ./devel/all_affs.sh || exit 3
GHA2DB_PROJECTS_YAML="cdf_projects.yaml" GHA2DB_RECENT_RANGE="4 hours" GHA2DB_TMOFFSET="-4" devstats
