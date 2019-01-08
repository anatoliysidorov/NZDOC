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
		SELECT ct.col_name
        INTO   :PlaceholderResult 
        FROM   tbl_caseCC c
		LEFT JOIN tbl_dict_casesystype ct ON ct.col_id = c.COL_CASECCDICT_CASESYSTYPE
        WHERE  c.col_id = v_caseid; 	
	ELSE
		SELECT ct.col_name
        INTO   :PlaceholderResult 
        FROM   tbl_case c 
		LEFT JOIN tbl_dict_casesystype ct ON ct.col_id = c.COL_CASEDICT_CASESYSTYPE
        WHERE  c.col_id = v_caseid; 	
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;