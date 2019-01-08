DECLARE
    v_CaseId Integer;
	v_data nclob :='[';

BEGIN
    BEGIN
      SELECT col_map_casestateinitcase into v_CaseId
        FROM tbl_map_casestateinitiation csi
        INNER JOIN tbl_caseevent ce on csi.col_id = ce.col_caseeventcasestateinit
        WHERE ce.col_id = :CaseEventId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 'CASE NOT FOUND';
    END;
    FOR rec in ( 
      SELECT col_ParamCode, col_ParamValue
        FROM Tbl_AutoRuleParameter
        WHERE col_caseeventautoruleparam = :CaseEventId
		)
        
        LOOP
        	 IF (UPPER(rec.col_ParamCode) != 'CaseId') THEN
            	v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
             END IF;
        END LOOP;

        v_data := v_data || '{"name": "CaseId", "value": ' || v_CaseId || '} ] ';

    RETURN v_data;
  END;