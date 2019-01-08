BEGIN
	SELECT '<b>' || col_name || '</b>'
	INTO :PlaceholderResult
	FROM tbl_doc_document
	WHERE col_id = :documentid;
EXCEPTION
WHEN no_data_found THEN
  :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
  :PlaceholderResult := 'SYSTEM ERROR';
END;