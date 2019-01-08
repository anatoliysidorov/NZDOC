DECLARE
  v_Id 			  NUMBER;
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NCLOB;  
   
BEGIN
  v_ErrorCode := 0;
  v_ErrorMessage := '';
  :affectedRows := 0;
  v_Id := :Id;    
    
    IF (v_Id IS NOT NULL) THEN
        DELETE TBL_STP_AVAILABLEADHOC 
        WHERE col_id = v_Id;        
    ELSIF(v_Id IS NULL) THEN
		v_ErrorMessage := 'Id can not be empty';
    	v_ErrorCode := 101;
		GOTO cleanup;
    END IF;
    
    :affectedRows := SQL%ROWCOUNT; 
     
    <<cleanup>>
    :ErrorMessage := v_ErrorMessage;
    :ErrorCode := v_ErrorCode;
END;