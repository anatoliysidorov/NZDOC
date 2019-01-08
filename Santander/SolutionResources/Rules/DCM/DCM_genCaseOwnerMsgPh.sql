DECLARE 
    --input/output
	v_caseid INTEGER; 	

	--internal
	v_inCache INTEGER;
   v_CSisInCache INTEGER; 
   
BEGIN 
    v_caseid := :CaseId; --because of legacy  
	v_inCache := f_DCM_isCaseInCache(CaseID => v_caseid);
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache
	
	--get case from proper place
	IF v_inCache = 1 THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   tbl_caseCC cse 
	  INNER JOIN vw_PPL_SimpleWorkBasket wb ON cse.COL_CASECCPPL_WORKBASKET = wb.id
		WHERE  cse.col_id = v_caseid; 	
  END IF;

    --new cache
  IF v_CSisInCache=1 THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   TBL_CSCASE cse 
	  INNER JOIN vw_PPL_SimpleWorkBasket wb ON cse.COL_CASEPPL_WORKBASKET = wb.id
		WHERE  cse.col_id = v_caseid;
	END IF;
  
  IF (v_inCache = 0) AND (v_CSisInCache=0) THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   tbl_case cse 
    INNER JOIN vw_PPL_SimpleWorkBasket wb ON cse.COL_CASEPPL_WORKBASKET = wb.id
		WHERE  cse.col_id = v_caseid;
	END IF;
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;