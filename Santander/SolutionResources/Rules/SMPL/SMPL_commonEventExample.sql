DECLARE
  v_caseId            NUMBER;  
  v_ErrorCode         NUMBER;
  v_ErrorMessage      NCLOB;
  v_validationresult  NUMBER; 
  v_input   CLOB;  
  v_InData  CLOB;
  v_outData CLOB;
   
BEGIN
  --INPUT
  v_caseId :=:CaseId;
  v_input  := :Input;
  v_InData := :InData;
  
  --INIT  
  v_outData          := NULL;
  v_ErrorCode        := 0; 
  v_ErrorMessage     := NULL; 
  v_validationresult := 1; --valid by default
   
  --
  -- do something with data
  --
  
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :validationResult := v_validationresult;
  --: OutData := v_outData;
  RETURN 0;
  
  <<cleanup>>
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :validationResult := v_validationresult;
  --: OutData := v_outData;
  RETURN -1;
   
END;