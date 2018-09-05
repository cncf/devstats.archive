CREATE FUNCTION current_state.label_prefix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%/%'
  THEN split_part($1, '/', 1)
ELSE
  'general'
END;
$_$;
