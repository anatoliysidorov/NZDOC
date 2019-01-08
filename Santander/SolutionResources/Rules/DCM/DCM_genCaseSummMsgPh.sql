DECLARE 
    --input
	v_caseid INTEGER; 	

	--internal
	v_inCache INTEGER;
BEGIN 
    v_caseid := :CaseId;
	v_inCache := f_DCM_isCaseInCache(CaseiD => v_caseid);
	
	--get case from proper place
	IF v_inCache = 1 THEN
		SELECT col_summary
        INTO   :PlaceholderResult 
        FROM   tbl_caseCC 
        WHERE  col_id = v_caseid; 	
	ELSE
		SELECT col_summary 
        INTO   :PlaceholderResult 
        FROM   tbl_case 
        WHERE  col_id = v_caseid; 	
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;