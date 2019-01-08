DECLARE
    v_CommonEventId Integer;
	v_data nclob :='[';

BEGIN
    BEGIN
      SELECT ce.col_id into v_CommonEventId
        FROM tbl_commonevent ce
        WHERE ce.col_id = :CommonEventId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 'COMMON EVENT NOT FOUND';
    END;
    FOR rec in ( 
      SELECT col_ParamCode, col_ParamValue
        FROM Tbl_AutoRuleParameter
        WHERE col_autoruleparamcommonevent = :CommonEventId
		)
        
        LOOP
        	 IF (UPPER(rec.col_ParamCode) != 'CommonEventId') THEN
            	v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
             END IF;
        END LOOP;

        v_data := v_data || '{"name": "CommonEventId", "value": ' || v_CommonEventId || '} ] ';

    RETURN v_data;
  END;