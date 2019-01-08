  DECLARE 
    --input/output
	v_caseid INTEGER; 	

	--internal
	v_inCache INTEGER;
  v_CSisInCache INTEGER;
  
BEGIN 
    v_caseid := :CaseId; --because of legacy  
	v_inCache := f_DCM_isCaseInCache(CaseiD => v_caseid);
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache
	
	--get case from proper place
	IF v_inCache = 1 THEN
		SELECT cs.col_name 
        INTO   :PlaceholderResult  
        FROM   tbl_caseCC cse 
               inner join tbl_cw_workitemCC cwi ON cse.COL_CW_WORKITEMCCCASECC = cwi.col_id 
               inner join tbl_dict_casestate cs ON cwi.COL_CW_WORKITEMCCPREVCASEST = cs.col_id 
        WHERE  cse.col_id = v_caseid; 	
  END IF;            

  --new cache
	IF v_CSisInCache=1 THEN  
		SELECT cs.col_name 
        INTO   :PlaceholderResult 
        FROM   TBL_CSCASE cse 
         inner join TBL_CSCW_WORKITEM cwi ON cse.COL_CW_WORKITEMCASE = cwi.col_id 
         inner join TBL_DICT_CASESTATE cs ON cwi.COL_CW_WORKITEMPREVCASESTATE = cs.col_id 
        WHERE  cse.col_id = v_caseid;
	END IF;
  
	IF (v_inCache = 0) AND (v_CSisInCache=0) THEN  
		SELECT cs.col_name 
        INTO   :PlaceholderResult 
        FROM   tbl_case cse 
               inner join tbl_cw_workitem cwi ON cse.COL_CW_WORKITEMCASE = cwi.col_id 
               inner join tbl_dict_casestate cs ON cwi.COL_CW_WORKITEMPREVCASESTATE = cs.col_id 
        WHERE  cse.col_id = v_caseid;
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;