DECLARE 
    v_caseparty_id    NUMBER; 
    v_caseid          NUMBER; 
    v_CSisInCache     INTEGER;
    v_ParticipantCode  VARCHAR2(255);
    
BEGIN 
--IN
  v_caseid := :CaseId;
  v_ParticipantCode := :ParticipantCode;

  --INIT
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache
	
  
  --case not in cache
  IF v_CSisInCache=0 THEN
    SELECT cp.col_id  INTO   v_caseparty_id 
    FROM TBL_CASEPARTY cp 
    LEFT JOIN TBL_PARTICIPANT p ON ( p.col_id = cp.col_casepartyparticipant ) 
    WHERE  cp.col_casepartycase = v_caseid
         AND Lower(p.col_code) = Lower(v_ParticipantCode) 
         AND ROWNUM = 1; 
  END IF;       

  --case in cache
  IF v_CSisInCache=1 THEN
    SELECT cp.col_id  INTO   v_caseparty_id 
    FROM TBL_CSCASEPARTY cp 
    LEFT JOIN TBL_PARTICIPANT p ON ( p.col_id = cp.col_casepartyparticipant ) 
    WHERE  cp.col_casepartycase = v_caseid
         AND Lower(p.col_code) = Lower(v_ParticipantCode) 
         AND ROWNUM = 1; 
  END IF;   
    
		   
    RETURN v_caseparty_id; 
EXCEPTION 
    WHEN OTHERS THEN 
      RETURN NULL; 
END; 