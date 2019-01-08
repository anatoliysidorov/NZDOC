DECLARE
  v_Domain            NVARCHAR2(255);
  v_UserAccessSubject NVARCHAR2(255);
  v_stNewId           NUMBER;
  v_stProcessedId     NUMBER;
  v_isValid           NUMBER;
  v_result            NUMBER;
     
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);

BEGIN
  v_Domain            := :pDomain;
  v_UserAccessSubject := :pUserAccessSubject;
  
  v_isValid         := 1;
  v_errorMessage    := NULL;
  v_errorCode       := NULL;
  v_stNewId         := NULL;
  v_stProcessedId   := NULL;
  
  BEGIN
    SELECT COl_ID INTO v_stNewId 
    FROM TBL_DICT_PROCESSINGSTATUS
    WHERE col_code='NEW';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorMessage  := 'Cant define a processing status "New" (DICT_PROCESSINGSTATUS)';
      v_errorCode     := 101;
      GOTO cleanup;
  END;

  BEGIN
    SELECT COl_ID INTO v_stProcessedId 
    FROM TBL_DICT_PROCESSINGSTATUS
    WHERE col_code='PROCESSED';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorMessage  := 'Cant define a processing status "Processed" (DICT_PROCESSINGSTATUS)';
      v_errorCode     := 101;
      GOTO cleanup;
  END;  

  --main query
  FOR rec IN
  (
    SELECT COl_ID AS queueId, COL_CASESLAEVTQCASE AS CaseId, COL_CASESLAEVTQSLAEVENT AS SSEID
    FROM TBL_CASESLAEVTQUEUE
    WHERE COL_CASESLAEVTQ_PROCST=v_stNewId
    ORDER BY COL_CASESLAEVTQCASE ASC, COL_CASESLAEVTQSLAEVENT ASC
  ) 
  LOOP
    v_result := f_DCM_processSLACasesActions(CASEID        =>rec.CaseId, 
                                             ERRORCODE     =>v_errorCode,     --output
                                             ERRORMESSAGE  =>v_errorMessage,  --output
                                             ISVALID       =>v_isValid,       --output
                                             SLAEVTID      =>rec.SSEID, 
                                             STATECONFIGID =>NULL, 
                                             PDOMAIN       =>v_Domain, 
                                             PUSERACCESSSUBJECT=>v_UserAccessSubject); 

    UPDATE TBL_CASESLAEVTQUEUE
    SET  COL_CASESLAEVTQ_PROCST=v_stProcessedId
    WHERE COL_ID=rec.queueId;   
  END LOOP;
  
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :IsValid := 1;--v_isValid;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :IsValid := 0;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1;
END;