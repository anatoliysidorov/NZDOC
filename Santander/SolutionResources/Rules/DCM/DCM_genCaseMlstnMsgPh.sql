DECLARE 
    --input/output
	v_caseid INTEGER; 	

	--internal
	v_inCache INTEGER;
  v_CSisInCache INTEGER;
  
BEGIN 
    v_caseid := :CaseId;
	v_inCache := f_DCM_isCaseInCache(CaseiD => v_caseid);
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache
	
	--get case from proper place
	IF v_inCache = 1 THEN 
		SELECT cs.col_name 
        INTO   :PlaceholderResult 
        FROM   tbl_caseCC cse 
               inner join tbl_dict_state cs ON cse.COL_CASECCDICT_STATE = cs.col_id 
        WHERE  cse.col_id = v_caseid; 	
  END IF;

  --new cache
	IF v_CSisInCache=1 THEN 
		SELECT cs.col_name 
        INTO   :PlaceholderResult 
        FROM   TBL_CSCASE cse 
        INNER JOIN TBL_DICT_STATE cs ON cse.COL_CASEDICT_STATE = cs.col_id 
        WHERE  cse.col_id = v_caseid;
	END IF;
  
	IF (v_inCache = 0) AND (v_CSisInCache=0) THEN
		SELECT cs.col_name 
        INTO   :PlaceholderResult 
        FROM   tbl_case cse 
               inner join tbl_dict_state cs ON cse.COL_CASEDICT_STATE = cs.col_id 
        WHERE  cse.col_id = v_caseid;
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;