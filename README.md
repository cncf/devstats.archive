[![Build Status](https://travis-ci.org/cncf/devstats.svg?branch=master)](https://travis-ci.org/cncf/devstats)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1357/badge)](https://bestpractices.coreinfrastructure.org/projects/1357)

# GitHub archives and git Grafana visualization dashboards

Authors: Łukasz Gryglicki <lgryglicki@cncf.io>, Justyna Gryglicka <lgryglicka@cncf.io>.

This is a toolset to visualize GitHub [archives](https://www.gharchive.org) using Grafana dashboards.

GHA2DB stands for **G**it**H**ub **A**rchives to **D**ash**B**oards.

More information about Kubernetes dashboards [here](https://github.com/cncf/devstats/blob/master/README_K8s.md).


# Kubernetes and Helm

Please see [example Helm chart](https://github.com/cncf/devstats-helm-example) for an example Helm deployment.

Please see [Helm chart](https://github.com/cncf/devstats-helm) for a full Helm deployment (work in progress).

Please see [LF Helm chart](https://github.com/cncf/devstats-helm-lf) for the LF Helm deployment (it is a data deployment, has no Grafana and uses ElasticSearch in addition to Postgres to store data).

Please see [GraphQL Helm chart](https://github.com/cncf/devstats-helm-graphql) for GraphQL foundation DevStats deployment.

Please see [Kubernetes dashboard](https://github.com/cncf/devstats-kubernetes-dashboard) if you want to enable a local dashboard to explore cluster state.

Please see [bare metal example](https://github.com/cncf/devstats-example) to see example bare metal deployment.

The rest of this document describes current bare metal deployment on packet.net used by CNCF projects.


# Presentations

- Presentations are available [here](https://github.com/cncf/devstats/blob/master/docs/presentation).
- Direct [link](https://docs.google.com/presentation/d/1v5zuSFQkwcthWXgS2p9vs9x5e4fnavMR8HdykS7aWYA/edit?usp=sharing).

# Deploying on your own project(s)

See the simple [DevStats example](https://github.com/cncf/devstats-example) repository for single project deployment (Homebrew), follow [instructions](https://github.com/cncf/devstats-example/blob/master/SETUP_OTHER_PROJECT.md) to deploy for your own project.

# Goal

We want to create a toolset for visualizing various metrics for the Kubernetes community (and also for all CNCF projects).

Everything is open source so that it can be used by other CNCF and non-CNCF open source projects.

The only requirement is that project must be hosted on a public GitHub repository/repositories.

# Data hiding

If you want to hide your data (replace with anon-#) please follow instructions [here](https://github.com/cncf/devstats/blob/master/HIDE_DATA.md).

# Forking and installing locally

This toolset uses only Open Source tools: GitHub archives, GitHub API, git, Postgres databases and multiple Grafana instances.
It is written in Go, and can be forked and installed by anyone.

Contributions and PRs are welcome.
If you see a bug or want to add a new metric please create an [issue](https://github.com/cncf/devstats/issues) and/or [PR](https://github.com/cncf/devstats/pulls).

To work on this project locally please fork the original [repository](https://github.com/cncf/devstats), and:
- [Compiling and running on Linux Ubuntu 18 LTS](./INSTALL_UBUNTU18.md).
- [Compiling and running on Linux Ubuntu 17](./INSTALL_UBUNTU17.md).
- [Compiling and running on Linux Ubuntu 16 LTS](./INSTALL_UBUNTU16.md).
- [Compiling and running on macOS](./INSTALL_MAC.md).
- [Compiling and running on FreeBSD](./INSTALL_FREEBSD.md).

Please see [Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md) for local development guide.

For more detailed description of all environment variables, tools, switches etc, please see [Usage](https://github.com/cncf/devstats/blob/master/USAGE.md).

# Metrics

We want to support all kind of metrics, including historical ones.
Please see [requested metrics](https://docs.google.com/document/d/1o5ncrY6lVX3qSNJGWtJXx2aAC2MEqSjnML4VJDrNpmE/edit?usp=sharing) to see what kind of metrics are needed.
Many of them cannot be computed based on the data sources currently used.

# Repository groups

There are some groups of repositories that are grouped together as a repository groups.
They are defined in [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql).

To setup default repository groups:
- `PG_PASS=pwd ./kubernetes/setup_repo_groups.sh`.

This is a part of `kubernetes/psql.sh` script and [kubernetes psql dump](https://devstats.cncf.io/gha.sql.xz) already has groups configured.

In an [All CNCF project](https://all.teststats.cncf.io) repository groups are mapped to individual CNCF projects [scripts/all/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/all/repo_groups.sql):

# Company Affiliations

We also want to have per company statistics. To implement such metrics we need a mapping of developers and their employers.

There is a project that attempts to create such mapping [cncf/gitdm](https://github.com/cncf/gitdm).

DevStats has an import tool that fetches company affiliations from `cncf/gitdm` and allows to create per company metrics/statistics. It also uses `companies.yaml` file to map company acquisitions (any data generated by company acquired by the another company is assigned to the latter using mapping from `companies.yaml`).

If you see errors in the company affiliations, please open a pull request on [cncf/gitdm](https://github.com/cncf/gitdm) and the updates will be reflected on [https://k8s.devstats.cncf.io](https://k8s.devstats.cncf.io) a couple days after the PR has been accepted. Note that gitdm supports mapping based on dates, to account for developers moving between companies.

New affiliations are imported into DevStats about 1-2 times/month.

# Architecture

For architecture details please see [architecture](https://github.com/cncf/devstats/blob/master/ARCHITECTURE.md) file.

Detailed usage is [here](https://github.com/cncf/devstats/blob/master/USAGE.md)

# Adding new metrics

Please see [metrics](https://github.com/cncf/devstats/blob/master/METRICS.md) to see how to add new metrics.

# Adding new projects

To add new project on a bare metal deployment follow [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) instructions.

See `cncf/devstats-helm-example`:`ADDING_NEW_PROJECTS.md` for informations about how to add more projects on Kubernetes/Helm deployment.

# Grafana dashboards

Please see [dashboards](https://github.com/cncf/devstats/blob/master/DASHBOARDS.md) to see list of already defined Grafana dashboards.

# Exporting data

Please see [exporting](https://github.com/cncf/devstats/blob/master/EXPORT.md).

# Detailed Usage instructions

- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)

# Servers

The servers to run `devstats` are generously provided by [Packet](https://www.packet.net/) bare metal hosting as part of CNCF's [Community Infrastructure Lab](https://github.com/cncf/cluster).

# One line run all projects

- Use `GHA2DB_PROJECTS_OVERRIDE="+cncf" PG_PASS=pwd devstats`.
- Or add this command using `crontab -e` to run every hour HH:08.

# Checking projects activity

- Use: `PG_PASS=... PG_DB=allprj ./devel/activity.sh '1 month,,' > all.txt`.
- Example results [here](https://teststats.cncf.io/all.txt) - all CNCF project activity during January 2018, excluding bots.
