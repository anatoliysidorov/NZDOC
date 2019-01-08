DECLARE
    --internal
    v_dsinterval NVARCHAR2(255);
    v_yminterval NVARCHAR2(255);
BEGIN
    --get data from proper place
    SELECT COL_INTERVALDS,
           COL_INTERVALYM
    INTO   v_dsinterval,
           v_yminterval
    FROM   tbl_DICT_StateSlaEvent sle
    WHERE  col_id = :StateSLAEventId;
    
    --normalize the intervals
    :PlaceholderResult := '{[this.INTERVAL(';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(YEAR FROM TO_YMINTERVAL(v_yminterval)) || ',';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(MONTH FROM TO_YMINTERVAL(v_yminterval)) || ',';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(DAY FROM TO_DSINTERVAL(v_dsinterval)) || ',';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(HOUR FROM TO_DSINTERVAL(v_dsinterval)) || ',';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(MINUTE FROM TO_DSINTERVAL(v_dsinterval)) || ',';
    :PlaceholderResult := :PlaceholderResult || EXTRACT(SECOND FROM TO_DSINTERVAL(v_dsinterval));
    :PlaceholderResult := :PlaceholderResult || ')]}';
    :PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';
EXCEPTION
WHEN no_data_found THEN
    :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
    :PlaceholderResult := 'SYSTEM ERROR';
END;