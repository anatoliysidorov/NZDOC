DECLARE
  v_CaseId        NUMBER;  
  v_Summary       NVARCHAR2(255);
  v_Description   NCLOB;
  v_Result        NUMBER;
  v_CustomData    NCLOB;
  v_SubmittedCustomData NCLOB;
  v_Priority_id       NUMBER;
  v_Draft             INTEGER;
  v_JustCustomData    INTEGER;  
  v_ErrorCode         NUMBER;
  v_ErrorMessage      NVARCHAR2(255);  
  v_Context           NVARCHAR2(255);  
  v_SuccessResponse   NVARCHAR2(255);
  
BEGIN
  --INPUT
  v_CaseId                := :ID;
  v_Summary               := :SUMMARY;
  v_Description           := :DESCRIPTION;
  v_SubmittedCustomData   := :CUSTOMDATA;
  v_Priority_id           := :PRIORITY_ID;
  v_Draft                 := :DRAFT;
  v_JustCustomData        := :JUSTCUSTOMDATA;
  v_Context               := NVL(:Context, 'UPDATE_CASE_DATA');
  
  --UPDATE DATA
  BEGIN
    v_Result := f_DAF_UpdateCaseDataFn(CASEID            =>v_caseid, 
                                       CONTEXT           =>v_Context,
                                       CUSTOMDATA        =>v_SubmittedCustomData, 
                                       DESCRIPTION       =>v_Description, 
                                       DRAFT             =>v_Draft,    
                                       ERRORCODE         =>v_errorcode, 
                                       ERRORMESSAGE      =>v_errormessage, 
                                       JUSTCUSTOMDATA    =>v_JustCustomData, 
                                       PRIORITY_ID       =>v_Priority_id,  
                                       SUCCESSRESPONSE   =>v_SuccessResponse, 
                                       SUMMARY           =>v_Summary);
    IF NVL(v_errorcode, 0)<>0 THEN GOTO cleanup; END IF;
  EXCEPTION 
    WHEN OTHERS THEN 
    v_errorcode := 102;
    v_errormessage := 'ERROR: Cant update a case data';
    GOTO cleanup;    
  END;
        
  :errorCode    := 0;
  :errorMessage := '';
  :SuccessResponse := v_SuccessResponse; 

  RETURN;
  
  <<cleanup>>  
  :errorCode     := v_errorcode;
  :errorMessage  := v_errormessage;	
  :SuccessResponse := '';

  ROLLBACK; 
  RETURN;

END;