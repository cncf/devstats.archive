CREATE FUNCTION current_state.label_suffix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%_/_%'
  THEN substring($1 FROM '/(.*)')
ELSE
  $1
END;
$_$;
