CREATE SCHEMA current_state;
ALTER SCHEMA current_state OWNER TO devstats_team;
CREATE FUNCTION current_state.label_prefix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%/%' 
  THEN split_part($1, '/', 1)
ELSE
  'general'
END;
$_$;
ALTER FUNCTION current_state.label_prefix(some_label text) OWNER TO devstats_team;
CREATE FUNCTION current_state.label_suffix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%/%'
  THEN substring($1 FROM '/(.*)') 
ELSE
  $1
END;
$_$;
ALTER FUNCTION current_state.label_suffix(some_label text) OWNER TO devstats_team;
CREATE MATERIALIZED VIEW current_state.issue_labels AS
 WITH label_fields AS (
         SELECT gha_issues_labels.issue_id,
            gha_issues_labels.label_id,
            gha_issues_labels.event_id,
            gha_issues_labels.dup_label_name
           FROM public.gha_issues_labels
        ), event_rank AS (
         SELECT gha_issues_labels.issue_id,
            gha_issues_labels.event_id,
            row_number() OVER (PARTITION BY gha_issues_labels.issue_id ORDER BY gha_issues_labels.event_id DESC) AS rank
           FROM public.gha_issues_labels
          GROUP BY gha_issues_labels.issue_id, gha_issues_labels.event_id
        )
 SELECT label_fields.issue_id,
    label_fields.label_id,
    label_fields.dup_label_name AS full_label,
    current_state.label_prefix((label_fields.dup_label_name)::text) AS prefix,
    current_state.label_suffix((label_fields.dup_label_name)::text) AS label
   FROM (label_fields
     JOIN event_rank ON (((label_fields.issue_id = event_rank.issue_id) AND (label_fields.event_id = event_rank.event_id) AND (event_rank.rank = 1))))
  ORDER BY label_fields.issue_id, (current_state.label_prefix((label_fields.dup_label_name)::text)), (current_state.label_suffix((label_fields.dup_label_name)::text))
  ;
ALTER TABLE current_state.issue_labels OWNER TO devstats_team;
CREATE MATERIALIZED VIEW current_state.milestones AS
 WITH milestone_latest AS (
         SELECT gha_milestones.id,
            gha_milestones.title AS milestone,
            gha_milestones.state,
            gha_milestones.created_at,
            gha_milestones.updated_at,
            gha_milestones.closed_at,
            gha_milestones.event_id,
            gha_milestones.dup_repo_id AS repo_id,
            gha_milestones.dup_repo_name AS repo_name,
            row_number() OVER (PARTITION BY gha_milestones.id ORDER BY gha_milestones.updated_at DESC, gha_milestones.event_id DESC) AS rank
           FROM public.gha_milestones
        )
 SELECT milestone_latest.id,
    milestone_latest.milestone,
    milestone_latest.state,
    milestone_latest.created_at,
    milestone_latest.updated_at,
    milestone_latest.closed_at,
    milestone_latest.repo_id,
    milestone_latest.repo_name
   FROM milestone_latest
  WHERE (milestone_latest.rank = 1)
  ;
ALTER TABLE current_state.milestones OWNER TO devstats_team;
CREATE MATERIALIZED VIEW current_state.issues AS
 WITH issue_latest AS (
         SELECT issues.id,
            issues.dup_repo_id AS repo_id,
            issues.dup_repo_name AS repo_name,
            issues.number,
            issues.is_pull_request,
            issues.milestone_id,
            milestones.milestone,
            issues.state,
            issues.title,
            issues.user_id AS creator_id,
            issues.assignee_id,
            issues.dup_created_at AS created_at,
            issues.updated_at,
            issues.closed_at,
            issues.body,
            issues.comments,
            row_number() OVER (PARTITION BY issues.id ORDER BY issues.updated_at DESC, issues.event_id DESC) AS rank
           FROM (public.gha_issues issues
             JOIN current_state.milestones ON ((issues.milestone_id = milestones.id)))
        )
 SELECT issue_latest.id,
    issue_latest.repo_id,
    issue_latest.repo_name,
    issue_latest.number,
    issue_latest.is_pull_request,
    issue_latest.milestone_id,
    issue_latest.milestone,
    issue_latest.state,
    issue_latest.title,
    issue_latest.creator_id,
    issue_latest.assignee_id,
    issue_latest.created_at,
    issue_latest.updated_at,
    issue_latest.closed_at,
    issue_latest.body,
    issue_latest.comments
   FROM issue_latest
  WHERE (issue_latest.rank = 1)
  ORDER BY issue_latest.repo_name, issue_latest.number
  ;
ALTER TABLE current_state.issues OWNER TO devstats_team;
CREATE TABLE current_state.priorities (
    priority text,
    label_sort integer
);
ALTER TABLE current_state.priorities OWNER TO devstats_team;
CREATE VIEW current_state.issues_by_priority AS
 WITH prior_groups AS (
         SELECT COALESCE(priorities.priority, 'no priority'::text) AS priority,
            COALESCE(priorities.label_sort, 99) AS label_sort,
            count(*) FILTER (WHERE ((issues.state)::text = 'open'::text)) AS open_issues,
            count(*) FILTER (WHERE ((issues.state)::text = 'closed'::text)) AS closed_issues
           FROM ((current_state.issues
             LEFT JOIN current_state.issue_labels ON (((issues.id = issue_labels.issue_id) AND (issue_labels.prefix = 'priority'::text))))
             LEFT JOIN current_state.priorities ON ((issue_labels.label = priorities.priority)))
          WHERE (((issues.milestone)::text = 'v1.11'::text) AND ((issues.repo_name)::text = 'kubernetes/kubernetes'::text) AND (NOT issues.is_pull_request))
          GROUP BY COALESCE(priorities.priority, 'no priority'::text), COALESCE(priorities.label_sort, 99)
        UNION ALL
         SELECT 'TOTAL'::text AS text,
            999,
            count(*) FILTER (WHERE ((issues.state)::text = 'open'::text)) AS open_issues,
            count(*) FILTER (WHERE ((issues.state)::text = 'closed'::text)) AS closed_issues
           FROM current_state.issues
          WHERE (((issues.milestone)::text = 'v1.11'::text) AND ((issues.repo_name)::text = 'kubernetes/kubernetes'::text) AND (NOT issues.is_pull_request))
        )
 SELECT prior_groups.priority,
    prior_groups.open_issues,
    prior_groups.closed_issues
   FROM prior_groups
  ORDER BY prior_groups.label_sort;
ALTER TABLE current_state.issues_by_priority OWNER TO devstats_team;
CREATE MATERIALIZED VIEW current_state.prs AS
 WITH pr_latest AS (
         SELECT prs.id,
            prs.dup_repo_id AS repo_id,
            prs.dup_repo_name AS repo_name,
            prs.number,
            prs.milestone_id,
            milestones.milestone,
            prs.state,
            prs.title,
            prs.user_id AS creator_id,
            prs.assignee_id,
            prs.dup_created_at AS created_at,
            prs.updated_at,
            prs.closed_at,
            prs.merged_at,
            prs.body,
            prs.comments,
            row_number() OVER (PARTITION BY prs.id ORDER BY prs.updated_at DESC, prs.event_id DESC) AS rank
           FROM (public.gha_pull_requests prs
             LEFT JOIN current_state.milestones ON ((prs.milestone_id = milestones.id)))
        )
 SELECT pr_latest.id,
    pr_latest.repo_id,
    pr_latest.repo_name,
    pr_latest.number,
    pr_latest.milestone_id,
    pr_latest.milestone,
    pr_latest.state,
    pr_latest.title,
    pr_latest.creator_id,
    pr_latest.assignee_id,
    pr_latest.created_at,
    pr_latest.updated_at,
    pr_latest.closed_at,
    pr_latest.merged_at,
    pr_latest.body,
    pr_latest.comments
   FROM pr_latest
  WHERE (pr_latest.rank = 1)
  ORDER BY pr_latest.repo_name, pr_latest.number
  ;
ALTER TABLE current_state.prs OWNER TO postgres;
CREATE INDEX issue_labels_issue_id ON current_state.issue_labels USING btree (issue_id);
CREATE INDEX issue_labels_label_parts ON current_state.issue_labels USING btree (prefix, label);
CREATE INDEX issue_labels_prefix ON current_state.issue_labels USING btree (prefix);
CREATE INDEX issues_id ON current_state.issues USING btree (id);
CREATE INDEX issues_milestone ON current_state.issues USING btree (milestone);
CREATE INDEX issues_number ON current_state.issues USING btree (number);
CREATE INDEX milestones_id ON current_state.milestones USING btree (id);
CREATE INDEX milestones_name ON current_state.milestones USING btree (milestone);
