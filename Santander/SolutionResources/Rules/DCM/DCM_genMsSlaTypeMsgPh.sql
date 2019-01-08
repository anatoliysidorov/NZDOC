BEGIN
    --get data
    SELECT    et.col_name
    INTO      :PlaceholderResult
    FROM      tbl_DICT_StateSlaEvent sle
    LEFT JOIN tbl_DICT_SlaEventType et ON lower(et.col_code) = lower(sle.COL_SERVICETYPE)
    WHERE     sle.col_id = :StateSLAEventId;
    
    :PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';
EXCEPTION
WHEN no_data_found THEN
    :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
    :PlaceholderResult := 'SYSTEM ERROR';
END;