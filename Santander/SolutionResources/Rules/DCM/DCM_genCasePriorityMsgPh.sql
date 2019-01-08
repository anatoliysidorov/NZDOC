  DECLARE 
    --input/output 
    v_caseid  INTEGER; 
	
    --internal 
    v_incache INTEGER; 
    v_CSisInCache INTEGER; 
    
BEGIN 
    v_caseid := :CaseId; 
    v_incache := F_dcm_iscaseincache(caseid => v_caseid); 
    v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

    --get case from proper place 
    IF v_incache = 1 THEN 
      SELECT p.col_name 
      INTO   :PlaceholderResult 
      FROM   tbl_casecc cse 
      INNER JOIN TBL_STP_PRIORITY p ON cse.col_stp_prioritycasecc = p.col_id 
      WHERE  cse.col_id = v_caseid; 
	END IF;

  --new cache
	IF v_CSisInCache=1 THEN   
      SELECT p.col_name 
      INTO   :PlaceholderResult 
      FROM   TBL_CSCASE cse 
      INNER JOIN TBL_STP_PRIORITY p ON cse.col_stp_prioritycase = p.col_id 
      WHERE  cse.col_id = v_caseid; 
  END IF; 
  
	IF (v_inCache = 0) AND (v_CSisInCache=0) THEN 
      SELECT p.col_name 
      INTO   :PlaceholderResult 
      FROM   TBL_CASE cse 
     INNER JOIN TBL_STP_PRIORITY p ON cse.col_stp_prioritycase = p.col_id 
      WHERE  cse.col_id = v_caseid; 
  END IF; 

    :PlaceholderResult := '<b>' || :PlaceholderResult || '</b>'; 
EXCEPTION 
    WHEN no_data_found THEN 
      :PlaceholderResult := 'NONE'; 
    WHEN OTHERS THEN 
      :PlaceholderResult := 'SYSTEM ERROR'; 
END; 