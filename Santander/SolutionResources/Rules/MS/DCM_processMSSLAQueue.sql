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
    SELECT COl_ID AS queueId, COL_MSSLAQUEUECASE AS CaseId, COL_SLAQUEUEDICT_STSLAEVENT AS SSEID
    FROM TBL_MSSLAQUEUE
    WHERE COL_SLAQUEUEDICT_PROCSTATUS=v_stNewId  AND NVL(COL_DATAFLAG,0)=0
    ORDER BY COL_MSSLAQUEUECASE ASC, COL_SLAQUEUEDICT_STSLAEVENT ASC
  ) 
  LOOP
    v_result := f_DCM_processMSSLAActions(CASEID        =>rec.CaseId, 
                                          ERRORCODE     =>v_errorCode, 
                                          ERRORMESSAGE  =>v_errorMessage, 
                                          ISVALID       =>v_isValid, 
                                          SLAEVTID      =>rec.SSEID, 
                                          STATECONFIGID =>NULL, 
                                          PDOMAIN       =>v_Domain, 
                                          PUSERACCESSSUBJECT=>v_UserAccessSubject); 

    UPDATE TBL_MSSLAQUEUE
    SET  COL_SLAQUEUEDICT_PROCSTATUS=v_stProcessedId
    WHERE COL_ID=rec.queueId;

    --delete a record(s) of Event Ids what will be excluded from execution
 /* a code is working (commented by VV)
     now we use a "transition way" for a solve this issue    
    DELETE FROM TBL_MSSLAQUEUE
    WHERE COL_MSSLAQUEUECASE=rec.CaseId AND
          COL_SLAQUEUEDICT_STSLAEVENT = rec.SSEID AND
          COL_DATAFLAG=1;
*/    
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