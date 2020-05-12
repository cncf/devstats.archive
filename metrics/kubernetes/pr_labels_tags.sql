select
  *
from (
  values
    ('All labels combined'),
    ('cla: no'),
    ('cncf-cla: no'),
    ('do-not-merge'),
    ('do-not-merge/blocked-paths'),
    ('do-not-merge/cherry-pick-not-approved'),
    ('do-not-merge/hold'),
    ('do-not-merge/release-note-label-needed'),
    ('do-not-merge/work-in-progress'),
    ('priority/critical-urgent'),
    ('needs-ok-to-test'),
    ('needs-rebase'),
    ('needs-priority'),
    ('release-note-label-needed')
  ) as temp(cat)
;
