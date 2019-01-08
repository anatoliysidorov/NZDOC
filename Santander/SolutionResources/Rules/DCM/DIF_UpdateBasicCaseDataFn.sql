DECLARE
  v_CaseId INTEGER;  
  v_Summary NVARCHAR2(255);
  v_Description NCLOB;
  v_Result INTEGER;
  v_Priority_id INTEGER;
  v_Draft INTEGER;
  v_Context NVARCHAR2(255);
  
BEGIN  
  --Input
  v_CaseId       := :CASEID;
  v_Summary      := :SUMMARY;
  v_Priority_id  := :PRIORITY_ID;
  v_Draft        := :DRAFT;
  v_Context      := :Context;

  --Output
  :ERRORCODE    := NULL;
  :ERRORMESSAGE := '';
    
  --UPDATE OTHER CASE DATA
  BEGIN
    UPDATE TBL_CASE
    SET    
      COL_SUMMARY = V_Summary,
      COL_STP_PRIORITYCASE = v_Priority_id,
      COL_DRAFT = v_Draft
    WHERE col_id = v_CaseId;
  EXCEPTION 
    WHEN OTHERS THEN 
    :ERRORCODE := 101;
    :ERRORMESSAGE := 'Update was unsuccessfull';
    RETURN -1;
  END;
  
  :ERRORCODE :=NULL;
  :ERRORMESSAGE := '';
  
  RETURN 0;

END;