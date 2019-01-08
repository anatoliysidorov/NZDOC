declare  
  v_Source        NVARCHAR2(255);
  v_Target        NVARCHAR2(255);
  v_Transition    NVARCHAR2(255);
  v_NextActivity  NVARCHAR2(255);
  v_CaseId        NUMBER;
  v_stateConfigId NUMBER;
  v_NextStateId   NUMBER;
  v_TransitionId  NUMBER;
   
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
   
begin
  
  v_Source := :Source;
  v_Target := :Target;
  v_CaseId := :CaseId;
  v_stateConfigId := :StateConfigId;
  v_TransitionId  := :TransitionId;

  v_Transition    := 'NONE';
  v_NextActivity  := NULL;
  v_errorMessage  := NULL;
  v_errorCode     := NULL;
  v_NextStateId   := NULL;
  
  IF (v_Source IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Source Activity value cannot be NULL';
    GOTO cleanup;
  END IF;

  IF (v_Target IS NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A Target Activity value cannot be NULL';
    GOTO cleanup;
  END IF;

  IF (v_CaseId IS NULL) AND (v_stateConfigId IS  NULL) THEN
    v_errorCode :=101;
    v_errorMessage :='A both Id values cannot be NULL';
    GOTO cleanup;
  END IF;


  IF v_stateConfigId IS NULL THEN
    BEGIN
      SELECT sc.COL_ID INTO v_stateConfigId
      FROM TBL_DICT_STATECONFIG SC 
      WHERE sc.COL_ISCURRENT=1 and
            sc.COL_CASESYSTYPESTATECONFIG = (select col_casedict_casesystype from tbl_case where col_id = v_CaseId);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN      
        v_errorCode := 104;
        v_errorMessage := 'State Config Id not found';
        GOTO cleanup;      
    END;
  END IF;

  BEGIN
    SELECT cst.col_transition, csts.COL_ACTIVITY, cst.col_targettransitionstate
    INTO v_Transition, v_NextActivity, v_NextStateId
    FROM TBL_DICT_TRANSITION cst
    INNER JOIN tbl_dict_state csss on cst.col_sourcetransitionstate = csss.col_id
    INNER JOIN tbl_dict_state csts on cst.col_targettransitionstate = csts.col_id
    WHERE csss.col_activity = v_Source and csts.col_activity = v_Target
    AND NVl(csss.col_statestateconfig,0) = v_stateConfigId
    AND NVL(csts.col_statestateconfig,0) = v_stateConfigId;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
      v_Transition := 'NONE';      
    WHEN TOO_MANY_ROWS THEN
      v_Transition := 'NONE';      
  END;
  
  IF v_Transition='NONE' THEN
    BEGIN
      SELECT cst.col_transition, csts.COL_ACTIVITY, cst.col_targettransitionstate
      INTO v_Transition, v_NextActivity, v_NextStateId
      FROM TBL_DICT_TRANSITION cst
      INNER JOIN tbl_dict_state csss on cst.col_sourcetransitionstate = csss.col_id
      INNER JOIN tbl_dict_state csts on cst.col_targettransitionstate = csts.col_id      
      WHERE cst.COL_ID=NVL(v_TransitionId,0);
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN
        v_Transition := 'NONE';  
        GOTO cleanup;        
      WHEN TOO_MANY_ROWS THEN
        v_Transition := 'NONE';      
        GOTO cleanup;        
    END;  
  END IF;
      
  v_errorCode :=NULL;
  v_errorMessage :=NULL;

  :NextStateId := v_NextStateId;
  :Transition := v_Transition;
  :NextActivity := v_NextActivity;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;
  RETURN 0;  

  --error block
  <<cleanup>>
  :NextStateId := v_NextStateId;
  :Transition := v_Transition;
  :NextActivity := v_NextActivity;
  :ErrorCode := v_errorCode;
  :ErrorMessage := v_errorMessage;  
  RETURN -1; 

end;