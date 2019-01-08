DECLARE
  v_CaseId Integer;
	v_data nclob :='[';

BEGIN
    BEGIN
      SELECT col_map_casestateinitcccasecc into v_CaseId
        FROM tbl_map_casestateinitcc csi
        INNER JOIN tbl_caseeventcc ce on csi.col_id = ce.col_caseeventcccasestinitcc
        WHERE ce.col_id = :CaseEventId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN 'CASE NOT FOUND';
    END;
    FOR rec in ( 
      SELECT col_ParamCode, col_ParamValue
        FROM tbl_autoruleparamcc
        WHERE col_caseeventccautoruleparcc = :CaseEventId
		)
        
        LOOP
        	 IF (UPPER(rec.col_ParamCode) != 'CaseId') THEN
            	v_data := v_data || '{"name": "' || rec.col_ParamCode || '", "value": "' || rec.col_ParamValue || '"},';
             END IF;
        END LOOP;

        v_data := v_data || '{"name": "CaseId", "value": ' || v_CaseId || '} ] ';

    RETURN v_data;
  END;