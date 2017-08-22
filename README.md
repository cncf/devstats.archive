# GitHub Archives Visualisation

This is a toolset to visualize GitHub archives using Grafana dashboards.

# Goal

We want to create various metrics visualization toolset for Kubernetes community.

It already have some metrics visualization: `kubernetes/test-infra` velodrome.

This project aims to add new metrics for existing Grafana dashboards.

We want to support all kind of metrics, including historical ones.

Current Velodrome implementation uses GitHub API to get its data. This has some limitations:
- It is not able to get repo, PR state at any given point of history
- It is limited by GitHub API points usage.

# GitHub ARchives

My approach it to use GitHub archives instead.
Possible approaches are:

1) BigQuery:
- You can query any data You want, but structure is quite flat and entire GitHub event payloads are stored as single column containing JSON text. This limits usage due to need of parsing that JSON in DB queries.
- BigQuery is paid, and is quite expensive.

2) GitHub API:
- You can get current state of the objects, but You cannot get repo, PR, issue state in the past (for example summary fields etc)
- It is limited by GitHub API usage per hour, which makes local development harder
- It is much slower than processing GitHub archives or BigQuery
- You can You GitHub hook callbacks, but they only fire for current events

3) GitHub archives
- All GitHub events are packed into multi-json gizpped files for each hour, You need to extract all hours (since Kubernetes project started) and filter 3 kubernetes orgs events
- This is a lot of data to process, but You have all possible GiutHub events in the past, processing 2 years of this data takes 12 hours, but this is done already and must be done only once
- You are getting all possible events, and all of them include current state of PRs, issues, repos at given point in time
- Processing of GitHub archives is free, so local developement is easy
- There is already implemented proof of concept (POC), please see `README.ruby.md`
