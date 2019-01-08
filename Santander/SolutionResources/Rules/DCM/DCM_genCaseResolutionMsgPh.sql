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
		SELECT rc.col_name 
    INTO   :PlaceholderResult 
    FROM   TBL_CASECC cse 
    INNER JOIN TBL_STP_RESOLUTIONCODE rc ON cse.COL_STP_RESOLUTIONCODECASECC = rc.col_id
    WHERE  cse.col_id = v_caseid; 	
   END IF;
   
  --new cache
  IF v_CSisInCache=1 THEN
		SELECT rc.col_name 
    INTO   :PlaceholderResult 
    FROM   TBL_CSCASE cse 
    INNER JOIN TBL_STP_RESOLUTIONCODE rc ON cse.COL_STP_RESOLUTIONCODECASE = rc.col_id
    WHERE  cse.col_id = v_caseid;
	END IF;
    
  IF (v_inCache = 0) AND (v_CSisInCache=0) THEN
		SELECT rc.col_name 
    INTO   :PlaceholderResult 
    FROM   tbl_case cse 
    INNER JOIN TBL_STP_RESOLUTIONCODE rc ON cse.COL_STP_RESOLUTIONCODECASE = rc.col_id
    WHERE  cse.col_id = v_caseid;
	END IF;  
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;