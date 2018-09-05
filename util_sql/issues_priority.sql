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
