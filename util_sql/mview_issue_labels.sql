create materialized view current_state.issue_labels as
with label_fields as (
          select gha_issues_labels.issue_id,
             gha_issues_labels.label_id,
             gha_issues_labels.event_id,
             gha_issues_labels.dup_label_name
            from gha_issues_labels
         ), event_rank as (
          select gha_issues_labels.issue_id,
             gha_issues_labels.event_id,
             row_number() over (partition by gha_issues_labels.issue_id order by gha_issues_labels.event_id desc) as rank
            from gha_issues_labels
           group by gha_issues_labels.issue_id, gha_issues_labels.event_id
         )
select label_fields.issue_id,
     label_fields.label_id,
     label_fields.dup_label_name as full_label,
     current_state.label_prefix((label_fields.dup_label_name)::text) as prefix,
     current_state.label_suffix((label_fields.dup_label_name)::text) as label
    from (label_fields
      join event_rank on (((label_fields.issue_id = event_rank.issue_id) and (label_fields.event_id = event_rank.event_id) and (event_rank.rank = 1))))
order by label_fields.issue_id, (current_state.label_prefix((label_fields.dup_label_name)::text)), (current_state.label_suffix((label_fields.dup_label_name)::text));
