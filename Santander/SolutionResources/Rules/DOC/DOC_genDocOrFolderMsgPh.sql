BEGIN
    SELECT
           CASE NVL(COL_ISFOLDER, 0)
                  WHEN 1 THEN 'Folder' ELSE 'File'
           END
    INTO   :PlaceholderResult
    FROM   TBL_DOC_DOCUMENT
    WHERE  COL_ID = :documentid;

:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';
EXCEPTION
WHEN no_data_found THEN
    :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
    :PlaceholderResult := 'SYSTEM ERROR';
END;