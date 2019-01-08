DECLARE
  v_WorkitemId     NUMBER;
  
  v_transition     NVARCHAR2(255);
  v_target         NVARCHAR2(255);
  v_result         NUMBER;
  
  v_NextActivity   NVARCHAR2(255);
  v_CurrActivity   NVARCHAR2(255);
  
  v_stateConfigId  NUMBER;
  v_NextStateId    NUMBER;
  v_CurrStateId    NUMBER;

  --errors variables
  v_errorCode      NUMBER;
  v_errorMessage   NVARCHAR2(255);


BEGIN
  v_WorkitemId := :WorkitemId;
  v_target     := :Target;
        
  v_errorMessage  := NULL;
  v_errorCode     := NULL;

  v_stateConfigId := NULL;
  v_CurrActivity  := NULL;
  v_NextActivity  := NULL;
  v_NextStateId   := NULL;
  v_CurrStateId   := NULL;
      
  BEGIN
    SELECT pw.col_CurrMSActivity, pw.COL_PI_WORKITEMDICT_STATE          
    INTO v_CurrActivity, v_CurrStateId
    FROM TBL_PI_WORKITEM pw
    WHERE pw.col_id = v_WorkitemId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN      
      v_errorCode := 104;
      v_errorMessage := 'Workitem with Id '||TO_CHAR(NVL(v_WorkitemId,0))||' not found or Id cannot be NULL';
      GOTO cleanup;
  END;

  BEGIN
    SELECT s.COL_STATESTATECONFIG INTO v_stateConfigId
    FROM TBL_DICT_STATE s
    INNER JOIN TBL_DICT_STATECONFIG sc on sc.col_id = s.COL_STATESTATECONFIG
    INNER JOIN TBL_DICT_CASESTATE cs on cs.col_id = s.COL_STATECASESTATE
    LEFT JOIN TBL_DICT_STATECONFIGTYPE sct on sct.col_id = sc.COL_STATECONFSTATECONFTYPE
    WHERE UPPER(sct.COL_CODE) = 'DOCUMENT'    	
    	    AND sc.COL_ISCURRENT = 1 AND cs.COL_ISSTART = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN      
      v_errorCode := 104;
      v_errorMessage := 'State config Id not found';
      GOTO cleanup;
  END;

  BEGIN
    SELECT COL_ACTIVITY INTO v_NextActivity
    FROM TBL_DICT_STATE 
    WHERE COL_ACTIVITY = v_target
          AND NVL(COL_STATESTATECONFIG,0) = v_stateConfigId;          
  EXCEPTION
    WHEN NO_DATA_FOUND then
      v_errorCode := 105;
      v_errorMessage := 'Target Activity "'||v_target||'" not found in Dict_state or cannot be NULL';
      GOTO cleanup; 
  END;

  v_result := f_DCM_getMSTransitionData(TRANSITIONID =>NULL,
                                        CASEID=>NULL, 
                                        ERRORCODE =>v_errorCode, 
                                        ERRORMESSAGE=>v_errorMessage, 
                                        NEXTACTIVITY=>v_NextActivity,
                                        NEXTSTATEID => v_NextStateId, 
                                        SOURCE=>v_CurrActivity, 
                                        STATECONFIGID =>v_stateConfigId, 
                                        TARGET=>v_target, 
                                        TRANSITION=>v_transition);
  

  IF  NVL(v_errorCode, 0)<>0 THEN  GOTO cleanup; END IF;

  IF (v_transition = 'NONE') THEN
    v_errorCode := 105;
    v_errorMessage := 'Transition not found';
    GOTO cleanup; 
  END IF;

  --Routing
  UPDATE TBL_PI_WORKITEM 
  SET
    COL_PREVMSACTIVITY = COL_CURRMSACTIVITY
   ,COL_PREVPI_WORKITEMDICT_STATE = COL_PI_WORKITEMDICT_STATE
   ,COL_PI_WORKITEMDICT_STATE = v_NextStateId
   ,COL_CURRMSACTIVITY = v_NextActivity
  WHERE COL_ID= v_WorkitemId;


  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
 
 
  --error block
  <<cleanup>>
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage; 
  
END;