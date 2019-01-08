DECLARE
  v_taskIdFromAttribute INTEGER;
  v_taskId              NUMBER;
  v_caseId              NUMBER;
  v_caseId2             NUMBER;
  v_IsValid             NUMBER;
    
  v_nextCaseStateCode   NVARCHAR2(255);
  v_nextResolutionCode  NVARCHAR2(255);
  v_nextResolutionId    NUMBER;

  v_result              NUMBER;
  v_result2             NVARCHAR2(255);

  v_TaskTemplateId      NUMBER;
  v_input               NCLOB;

  v_message           NCLOB;
  v_validationresult  NUMBER;

  --temp variables for returns 
  v_tempErrMsg       NCLOB;   

  v_CustomData               NCLOB;  
  v_routecustomdataprocessor NVARCHAR2(255);

  v_transition          NVARCHAR2(255);
  v_NextActivity        NVARCHAR2(255);
  v_CurrActivity        NVARCHAR2(255);
  v_NextActivityName    NVARCHAR2(255);
  v_CurrActivityName    NVARCHAR2(255);
  
  v_SystemNextActivity  NVARCHAR2(255);
  v_SystemCurrActivity  NVARCHAR2(255);

  v_workitemCase        NUMBER;
  v_stateConfigId       NUMBER;
  v_caseSysTypeId       NUMBER;  
  v_CurrStateId         NUMBER;
  v_NextStateId         NUMBER;
  v_SystemCurrStateId   NUMBER;
  v_SystemNextStateId   NUMBER;
  v_resolutionAssigned  NUMBER;
  v_sysDate             DATE;
  v_SystemNextIsFinishFlag NUMBER;
  v_TransitionUCode     NVARCHAR2(255);

  v_CanRoute        NUMBER;
  v_CanClose        NUMBER;
  v_Attributes      NVARCHAR2(4000);
  v_TransitionId    NUMBER;
  v_CurrentSysStateID   INTEGER;
  v_CurrentOwnerWB      INTEGER;
  v_historymsg          NCLOB;
  v_outData CLOB;
  
  --errors variables
  v_errorCode     NUMBER;
  v_errorMessage  NVARCHAR2(255);
 
BEGIN
  --input
  v_taskId := :TaskId;
  v_input  := :Input;
  v_CustomData := NULL;

  v_IsValid          := NULL; 
  v_validationresult := 1;
  v_message          := '';

  v_errorMessage  := NULL;
  v_errorCode     := NULL;

  v_nextCaseStateCode := NULL;
  v_nextResolutionCode := NULL;
  v_nextResolutionId   := NULL;
  v_TaskTemplateId     := NULL;

  v_transition           := NULL; 
  v_NextActivity         := NULL;
  v_CurrActivity         := NULL;
  v_SystemNextActivity   := NULL;
  v_SystemCurrActivity   := NULL;
  v_NextActivityName     := NULL;
  v_CurrActivityName     := NULL;
  
  v_workitemCase         := NULL;
  v_stateConfigId        := NULL;
  v_caseSysTypeId        := NULL; 
  v_CurrStateId          := NULL;
  v_NextStateId          := NULL;
  v_SystemCurrStateId    := NULL;
  v_SystemNextStateId    := NULL;
  v_resolutionAssigned   := NULL;   
  v_taskIdFromAttribute  := NULL;
  v_sysDate              := SYSDATE;
  v_SystemNextIsFinishFlag := NULL;
  v_Attributes       := NULL;
  v_TransitionId     := NULL;
  v_TransitionUCode  := NULL;
  v_CurrentOwnerWB   := NULL;
  v_historymsg       := NULL;
  v_outData      := NULL;

/*
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('START', 'f_EVN_setCaseStateMS', NULL); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('---', 'v_taskId',TO_CHAR(v_taskId)); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('---', 'v_input',v_input); 
  --GOTO cleanup;

*/

  v_taskIdFromAttribute := f_FORM_getParamByName(v_input, 'TaskId');
  IF v_taskIdFromAttribute IS NOT NULL THEN
    v_taskId := v_taskIdFromAttribute;
  END IF;  
  
  IF (v_taskId IS NULL) THEN 
    v_errorCode :=101;
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'TaskId can not be empty');
    GOTO cleanup;
  END IF;

  v_caseId := f_DCM_getCaseIdByTaskId(TASKID => v_taskId);  

  IF v_caseId IS NULL THEN
    v_errorCode :=101;        
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'CaseId can not be empty');
    GOTO cleanup; 
  END IF;

  --define a current case data  
  BEGIN
    SELECT cs.COL_MILESTONEACTIVITY, cs.COL_CASECCDICT_CASESYSTYPE, cs.COL_CW_WORKITEMCCCASECC,
           cs.COL_CASECCDICT_STATE, s.COL_STATESTATECONFIG, s.COL_NAME, cs.COL_CASECCDICT_CASESTATE,
           cs.COL_CASECCPPL_WORKBASKET
    INTO v_CurrActivity, v_caseSysTypeId, v_workitemCase, v_CurrStateId, v_stateConfigId, v_CurrActivityName,
         v_CurrentSysStateID, v_CurrentOwnerWB 
    FROM TBL_CASECC cs
    LEFT OUTER JOIN TBL_DICT_STATE s ON s.COL_ID =cs.COL_CASECCDICT_STATE  
    WHERE cs.COL_ID = v_caseId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorCode     :=101;
      v_caseSysTypeId := NULL;            
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Case not found inside a cache. CaseId '||TO_CHAR(v_CaseId));
      GOTO cleanup;
  END;
     
  BEGIN
    SELECT col_activity INTO v_result2 
    FROM TBL_DICT_STATE 
    WHERE col_activity = v_CurrActivity
          AND NVL(col_statestateconfig,0) = v_stateConfigId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorCode :=101;
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Case milestone undefined.Source Activity is:"'||v_CurrActivity||'". StateConfigId '||TO_CHAR(v_stateConfigId));    
      GOTO cleanup;
  END;

  BEGIN 
    SELECT COL_ID2 INTO v_TaskTemplateId FROM TBL_TASKCC WHERE COL_ID=v_TaskId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorCode :=101;
      v_TaskTemplateId := NULL;        
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'TaskTemplateId can not be empty');
      GOTO cleanup; 
  END;

  --get target case state data
  v_nextCaseStateCode := f_FORM_getParamByName(v_input, 'CaseState');

  IF v_nextCaseStateCode IS NULL THEN
    BEGIN 
      SELECT arp.col_paramvalue INTO v_nextCaseStateCode 
      FROM TBL_AUTORULEPARAMTMPL arp
      INNER JOIN tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id 
      WHERE tsi.col_MAP_TaskStInitTplTaskTpl=v_TaskTemplateId  AND
            arp.col_AutoRuleParamTpCaseType=v_caseSysTypeId   AND
            UPPER(arp.col_paramcode)='CASESTATE';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_nextCaseStateCode := NULL;
      WHEN TOO_MANY_ROWS THEN    
        v_nextCaseStateCode := NULL;
    END;
  END IF;

  IF v_nextCaseStateCode IS NULL THEN
    v_errorCode :=101;       
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Target Activity Code undefined');
    GOTO cleanup; 
  END IF;

  --define a next activity
  BEGIN
    SELECT col_activity, COL_NAME INTO v_NextActivity, v_NextActivityName 
    FROM TBL_DICT_STATE 
    WHERE UPPER(COL_COMMONCODE) = UPPER(v_nextCaseStateCode)
          AND NVL(col_statestateconfig,0) = v_stateConfigId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      v_errorCode :=101;
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Target Activity undefined. '||
                                       'Code is "'||v_nextCaseStateCode||'". StateConfigId is '||TO_CHAR(v_stateConfigId));    
      GOTO cleanup;
  END;
   
  IF v_nextCaseStateCode ='DONTCHANGE' THEN
    v_NextActivity := v_CurrActivity;
  END IF;
   
  --get resolution code
  v_nextResolutionCode := f_FORM_getParamByName(v_input, 'ResolutionCode');

  IF v_nextResolutionCode IS NULL THEN
    BEGIN 
      SELECT arp.col_paramvalue INTO v_nextResolutionCode 
      FROM TBL_AUTORULEPARAMTMPL arp
      INNER JOIN tbl_map_taskstateinittmpl tsi on arp.col_RuleParTp_TaskStateInitTp = tsi.col_id 
      WHERE tsi.col_MAP_TaskStInitTplTaskTpl=v_TaskTemplateId  AND
            arp.col_AutoRuleParamTpCaseType=v_caseSysTypeId   AND
            UPPER(arp.col_paramcode)='RESOLUTIONCODE';
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_nextResolutionCode := NULL;
      WHEN TOO_MANY_ROWS THEN    
        v_nextResolutionCode := NULL;
    END;
  END IF;

  IF v_nextResolutionCode IS NULL THEN
    v_errorCode :=101;   
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'Resolution Code can not be empty');
    GOTO cleanup; 
  END IF;

  IF v_nextResolutionCode='DONTCHANGE' THEN
    SELECT col_stp_resolutioncodecasecc INTO v_nextResolutionId 
    FROM TBL_CASECC 
    WHERE COL_ID=v_caseid;
  ELSE
    v_nextResolutionId   := f_util_getidbycode(CODE => v_nextResolutionCode, TABLENAME => 'tbl_stp_resolutioncode');
  END IF;
  
  IF v_nextResolutionCode='RESET' THEN v_nextResolutionId :=NULL; END IF; 

/*   
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('before f_DCM_getMSTransitionData', 'SOURCE=>',v_CurrActivity); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('before f_DCM_getMSTransitionData', 'TARGET=>',v_NextActivity);
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('before f_DCM_getMSTransitionData', 'STATECONFIGID =>',TO_CHAR(v_stateConfigId));
*/  
  --ROUTING SECTION    
  v_result := f_DCM_getMSTransitionData(TRANSITIONID =>NULL,
                                        CASEID=>NULL, 
                                        ERRORCODE =>v_errorCode, 
                                        ERRORMESSAGE=>v_errorMessage, 
                                        NEXTACTIVITY=>v_NextActivity,
                                        NEXTSTATEID => v_NextStateId, 
                                        SOURCE=>v_CurrActivity, 
                                        STATECONFIGID =>v_stateConfigId, 
                                        TARGET=>v_NextActivity, 
                                        TRANSITION=>v_transition);
    

  IF  NVL(v_errorCode,0)<>0 THEN       
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => v_errorMessage);    
    GOTO cleanup;
  END IF;

  IF (v_transition <> 'NONE') THEN     
    BEGIN
      SELECT COL_ID, COL_COMMONCODE INTO v_TransitionId, v_TransitionUCode
      FROM TBL_DICT_TRANSITION cst
      WHERE COL_TRANSITION=v_transition;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN 
        v_TransitionId := NULL;      
        v_errorCode :=101;    
        v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Transition Id not found. From "'||
                                      v_CurrActivityName||'" to "'||v_NextActivityName||'"');        
        GOTO cleanup;
    END;
  END IF;

/*
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_NextStateId=>',TO_CHAR(v_NextStateId)); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_transition=>',v_transition);
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_transitionId=>', TO_CHAR(v_transitionId));
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_NextActivity =>',v_NextActivity);
*/
  IF (v_transition = 'NONE') THEN

    --try to route a case anyway  
    BEGIN
      SELECT s.COL_ID, s.COL_TRANSITION, s.COL_ACTIVITY, s.COL_TARGETTRANSITIONSTATE, s.COL_COMMONCODE 
      INTO v_TransitionId, v_Transition, v_NextActivity, v_NextStateId, v_TransitionUCode
      FROM
      ( 
        --this code is temporary (ask VV)   
        --do not modify
        SELECT ROWNUM AS RN, cst.COL_ID,  cst.COL_TRANSITION, csts.COL_ACTIVITY, 
               cst.COL_TARGETTRANSITIONSTATE, cst.COL_COMMONCODE
        FROM TBL_DICT_TRANSITION cst
        INNER JOIN tbl_dict_state csss on cst.col_sourcetransitionstate = csss.col_id
        INNER JOIN tbl_dict_state csts on cst.col_targettransitionstate = csts.col_id
        WHERE csss.col_activity = v_CurrActivity and csts.col_activity = v_NextActivity
        AND NVl(csss.col_statestateconfig,0) = v_stateConfigId
        AND NVL(csts.col_statestateconfig,0) = v_stateConfigId
      ) s
      WHERE s.RN=1;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN v_Transition := 'NONE';      
    END;

/*
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('try anyway f_DCM_getMSTransitionData', '---',NULL); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_NextStateId=>',TO_CHAR(v_NextStateId)); 
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_transition=>',v_transition);
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_transitionId=>', TO_CHAR(v_transitionId));
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('after f_DCM_getMSTransitionData', 'v_NextActivity =>',v_NextActivity);
*/

    IF v_Transition = 'NONE' THEN
      v_errorCode :=101;    
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Transition not found. From "'||
                                    v_CurrActivityName||'" to "'||v_NextActivityName||'"');        
      GOTO cleanup;     
    END IF;
  END IF;
 

  --get system state data
  IF v_NextStateId IS NOT NULL THEN
    BEGIN
      SELECT --st.col_id, st.COL_CODE, st.COL_NAME, 
             st.COL_STATECASESTATE
             --cst.COL_NAME, cst.COL_CODE, 
             ,cst.COL_ACTIVITY
             ,NVL(cst.COL_ISFINISH,0) 
             --,cst.COL_STATECONFIGCASESTATE
      INTO v_SystemNextStateId, v_SystemNextActivity, v_SystemNextIsFinishFlag
      FROM  TBL_DICT_STATE st
      INNER JOIN TBL_DICT_CASESTATE cst ON st.COL_STATECASESTATE=cst.col_id
      WHERE st.col_id=v_NextStateId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorCode := 101;        
        v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Cant define a system state parameters');    
        GOTO cleanup;     
    END;
  END IF;

  BEGIN
    SELECT s1.CaseId INTO v_CaseId2
    FROM
        (SELECT cs.col_id AS CaseId/*, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
                cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
                cast(substr(cse.col_description,1,2000) as nvarchar2(2000)) as CaseDescription,
                cwi.col_id as CaseWorkitemId*/
          FROM TBL_CASECC cs
          --INNER JOIN TBL_CASEEXT cse on cs.col_id = cse.col_caseextcase
          INNER JOIN TBL_CW_WORKITEMCC cwi on cs.col_cw_workitemcccasecc = cwi.col_id
          INNER JOIN TBL_DICT_CASESYSTYPE dcst on cs.col_caseccdict_casesystype = dcst.col_id
          INNER JOIN TBL_DICT_STATE ds on cs.COL_CaseCCDICT_State = ds.col_id
          WHERE cs.col_id = v_CaseId
                AND ds.col_activity = v_CurrActivity
         ) s1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorCode := 101;        
        v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Case cannot be moved');    
        GOTO cleanup;     
  END;

  v_Attributes :='<TaskId>'||TO_CHAR(v_taskId)||'</TaskId>'||
                 '<MilestoneActivity>'||TO_CHAR(v_CurrActivity)||'</MilestoneActivity>'||
                 '<MilestoneStateId>' || TO_CHAR(v_CurrStateId) || '</MilestoneStateId>'||
                 '<SystemStateId>' || TO_CHAR(v_CurrentSysStateID) || '</SystemStateId>'||
                 '<TargetMilestoneActivity>'||TO_CHAR(v_NextActivity)||'</TargetMilestoneActivity>'||
                 '<TargetMilestoneStateId>' || TO_CHAR(v_NextStateId) || '</TargetMilestoneStateId>'|| 
                 '<TargetSystemStateId>' || TO_CHAR(v_SystemNextStateId) || '</TargetSystemStateId>'||
                 '<TargetSystemStateIsFinish>' || TO_CHAR(v_SystemNextIsFinishFlag) || '</TargetSystemStateIsFinish>'||                                 
                 '<TransitionUCode>' || TO_CHAR(v_TransitionUCode) || '</TransitionUCode>'||
                 '<TransitionId>'||TO_CHAR(v_TransitionId)||'</TransitionId>'||
                 '<TransitionCode>'||TO_CHAR(v_transition)||'</TransitionCode>'||
                 '<TargetResolutionCode>'||TO_CHAR(v_nextResolutionCode)||'</TargetResolutionCode>'||
                 '<TargetResolutionId>'||TO_CHAR(v_nextResolutionId)||'</TargetResolutionId>'||
                 '<CurrentOwnerWBId>' || TO_CHAR(v_CurrentOwnerWB) || '</CurrentOwnerWBId>'||
                 '<StateConfigId>'||TO_CHAR(v_stateConfigId)||'</StateConfigId>';

/*
  INSERT INTO TBL_LOG (col_data1, col_data2, col_bigdata1)   values('BEFORE ROUTING VALIDATION EVENTS', 'v_Attributes=>',v_Attributes); 
*/

  --PROCESS EVENTS BEFORE ENTERING THE MILESTONE
  v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                         CASEID=> v_CaseId, 
                                         ERRORCODE=>v_errorCode, 
                                         ERRORMESSAGE =>v_errorMessage, 
                                         EVTMOMENT=>'BEFORE', 
                                         EVTSTATE=>v_NextActivity, 
                                         EVTTYPE=>'VALIDATION', 
                                         ISVALID=>v_IsValid, 
                                         STATECONFIGID=>v_stateConfigId);
  IF v_IsValid <> 1 THEN      
    v_errorCode := 101;
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Case transition validation failed.<p>Message: "' ||v_errorMessage||'"</p>');    
    GOTO cleanup;
  END IF;

  --VALIDATE THAT A CASE IS NOT BLOCKED BY ANY RELATED CASES
  v_IsValid :=1;
  v_result := f_DCM_validateCaseLinks(TRANSITIONID =>v_TransitionId,
                                      CASE_ID       =>v_CaseId, 
                                      ERRORCODE     =>v_errorCode,
                                      ERRORMESSAGE  =>v_errorMessage,
                                      TARGET        => v_NextActivity,
                                      CANROUTE => v_CanRoute,
                                      CANCLOSE => v_CanClose);
       

  IF NVL(v_errorCode,0) >0 OR v_CanRoute = 0 OR v_CanClose = 0 THEN 
    v_IsValid :=0; 
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => v_errorMessage);    
    GOTO cleanup;
  END IF;

  --VALIDATION PASSED
  BEGIN
    --PROCESS EVENTS BEFORE ENTERING THE MILESTONE  
    v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                           CASEID=> v_CaseId, 
                                           ERRORCODE=>v_errorCode, 
                                           ERRORMESSAGE =>v_errorMessage, 
                                           EVTMOMENT=>'BEFORE', 
                                           EVTSTATE=>v_NextActivity, 
                                           EVTTYPE=>'ACTION', 
                                           ISVALID=>v_IsValid, 
                                           STATECONFIGID=>v_stateConfigId);
    
    IF v_IsValid=0 THEN 
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => v_errorMessage);    
      GOTO cleanup;        
    END IF;

    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_IsValid := 1;
    
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'CASE_MS_ROUTE',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_IsValid);
    
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Validation Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF;
    
    IF NVL(v_IsValid, 0) = 0 THEN
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => v_errorMessage); 
      GOTO cleanup;
    END IF;


    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_IsValid := 1;    
    v_result := f_DCM_processCommonEvent(InData           => NULL,
                                         OutData          => v_outData, 
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'CASE_MS_ROUTE',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'ACTION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_IsValid);
    
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Action Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF;

    v_resolutionAssigned := 0;

    --CUSTOM ROUTING/SYSTEM ROUTING 
    UPDATE TBL_CASECC 
    SET COL_MILESTONEACTIVITY = v_NextActivity,
        COL_CaseCCDICT_State = v_NextStateId,
        COL_ACTIVITY = v_SystemNextActivity,
        COL_CASECCDICT_CASESTATE = v_SystemNextStateId,
        COL_PREVMSACTIVITY =  v_CurrActivity, 
        COL_PREVCASECCDICT_STATE  = v_CurrStateId
    WHERE COL_ID=v_CaseId;
            
    UPDATE TBL_CW_WORKITEMCC 
    SET col_activity = v_SystemNextActivity, 
        col_cw_workitemccprevcasest = col_cw_workitemccdict_casest, 
        col_cw_workitemccdict_casest = v_SystemNextStateId,
        col_PrevMSActivity = col_MilestoneActivity,
        col_PrevCWICCDICT_State = col_CWICCDICT_State,
        col_MilestoneActivity = v_NextActivity,
        col_CWICCDICT_State = v_NextStateId
    WHERE COL_ID = v_workitemCase;

    FOR rec2 IN
    (SELECT cst.col_code AS CaseStateSetupCode, cst.col_forcednull AS ForcedNull, 
            cst.col_forcedoverwrite AS ForcedOverwrite, cst.col_nulloverwrite as NullOverwrite
     FROM TBL_DICT_CASESTATE cs
     INNER JOIN TBL_DICT_CASESTATESETUP cst ON cs.COL_ID = cst.COL_CASESTATESETUPCASESTATE
     WHERE cs.COL_ACTIVITY = v_SystemNextActivity)

    LOOP
      IF rec2.CASESTATESETUPCODE = 'DATEASSIGNED' THEN
        IF rec2.ForcedNull = 1 THEN
          UPDATE TBL_CASECC  SET COL_DATEASSIGNED = NULL WHERE COL_ID = v_CaseId;

        ELSIF rec2.ForcedOverwrite = 1 THEN
          UPDATE TBL_CASECC  SET COL_DATEASSIGNED = v_sysdate  WHERE COL_ID = v_CaseId;

        elsif rec2.NullOverwrite = 1 then
          update tbl_casecc set col_dateassigned = v_sysdate where col_id = v_CaseId and col_dateassigned is null;
      END IF;

      ELSIF rec2.casestatesetupcode = 'DATECLOSED' THEN
        UPDATE TBL_CASECC SET COL_DATECLOSED = v_sysdate WHERE COL_ID = v_CaseId;

      ELSIF rec2.casestatesetupcode = 'WORKBASKET' THEN

        IF rec2.ForcedNull = 1 THEN
          UPDATE TBL_CASECC  SET COL_CASECCPPL_WORKBASKET = NULL WHERE COL_ID = v_CaseId;
        --ELSIF rec2.ForcedOverwrite = 1 THEN
        --  UPDATE TBL_CASECC  SET COL_CASECCPPL_WORKBASKET = NULL WHERE COL_ID = v_CaseId;
        END IF;

      ELSIF rec2.casestatesetupcode = 'RESOLUTION' THEN
        UPDATE TBL_CASECC SET COL_STP_RESOLUTIONCODECASECC = v_nextResolutionId 
        WHERE COL_ID = v_CaseId;
        v_resolutionAssigned := 1;
      END IF;
    END LOOP;

    --SET DATE EVENTS FOR MILESTONE ROUTE
    v_result := f_DCM_addCaseMSDateEventListCC(CASEID => v_CaseId, STATECONFIGID=>v_stateConfigId);

    --SET CASE DLINE AND GOAL SLA ON THE CURRENT ACTIVITY (use a simple hack with CaseInCache)
    v_result := f_DCM_updateCaseSlaDateTime(CASEID => v_CaseId, DateEventValue=>NULL);     

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      v_errorCode := 101;        
      v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => 'Case transition failed');
      GOTO cleanup;
  END;

  --CREATE NOTIFICATION
  v_result := f_DCM_createNotification(CASEID => v_CaseId, 
                                       NOTIFICATIONTYPECODE => 'CASE_MOVED', 
                                       TASKID => null);

  --INVALIDATE CASE WHERE CASE CHANGED ITS STATE
  IF v_resolutionAssigned = 0 THEN
    v_result := f_DCM_createCaseHistoryCC (MessageCode => 'CaseRouted', CaseId => v_CaseId, IsSystem => 0);
  ELSIF v_resolutionAssigned = 1 THEN
    v_result := f_DCM_createCaseHistoryCC (MessageCode => 'CaseRoutedWithResolution', CaseId => v_CaseId, IsSystem => 0);
  END IF;

  v_result := f_dcm_invalidatecase(CaseId => v_CaseId);

  v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>v_Attributes,
                                         CASEID=> v_CaseId, 
                                         ERRORCODE=>v_errorCode, 
                                         ERRORMESSAGE =>v_errorMessage, 
                                         EVTMOMENT=>'AFTER', 
                                         EVTSTATE=>v_NextActivity, 
                                         EVTTYPE=>'ACTION', 
                                         ISVALID=>v_IsValid, 
                                         STATECONFIGID=>v_stateConfigId);

  IF v_IsValid=0 THEN 
    v_message := f_UTIL_addToMessage(ORIGINALMSG => v_message, NEWMSG => v_errorMessage);    
    GOTO cleanup;        
  END IF;


  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CASE_MS_ROUTE- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_IsValid := 1;
  
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CASE_MS_ROUTE',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_IsValid);
  
  /*--write to history*/
  IF v_historymsg IS NOT NULL THEN
    v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                       issystem       => 0,
                                       MESSAGE        => 'Action Common event(s)',
                                       messagecode    => 'CommonEvent',
                                       targetid       => v_caseid,
                                       targettype     => 'CASE');
  END IF;
 

  v_result := f_dcm_statCaseCalcCC(CaseId => v_CaseId);

  IF v_SystemNextIsFinishFlag=1 THEN
    v_result := f_DCM_statCaseUpdateCC(CaseId => v_CaseId);
  END IF;
                                   
  IF v_IsValid=0 THEN GOTO cleanup; END IF;
  
  --CALL CUSTOM PROCESSOR IF ONE EXISTS
  begin 
    select col_routecustomdataprocessor
    into   v_routecustomdataprocessor
    from tbl_dict_casesystype
    where col_id = v_caseSysTypeId;
    exception
    when NO_DATA_FOUND THEN
    v_routecustomdataprocessor := null;
  end;
  IF v_CustomData is not null and v_routecustomdataprocessor is not null THEN
    v_result := f_dcm_invokeCaseCusDataProc(CaseId => v_caseId, Input => v_CustomData, ProcessorName => v_routecustomdataprocessor);
  ELSIF v_CustomData is not null THEN
    --set custom data XML IF no special processor passed
    update tbl_caseext
    set col_customdata = XMLTYPE(v_CustomData)
    where col_caseextcase = v_caseId;
  end IF;

  v_errorCode :=NULL;
  v_errorMessage :=NULL;
  v_message :='Success';
  :Message := v_message;
  :ValidationResult := 1;

  --ErrorCode := v_errorCode;
  --ErrorMessage := v_errorMessage;
  RETURN 0; 
  
 --ERROR BLOCK
 <<cleanup>>  
 
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'WARNING: something went wrong');
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_errorCode);
 v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MESSAGE: ' || v_message);
  
 v_result := f_HIST_createHistoryFn(
  AdditionalInfo => v_message,  
  IsSystem=>0, 
  Message=> NULL,
  MessageCode => 'GenericEventFailure', 
  TargetID => v_caseId, 
  TargetType=>'CASE'
 );  
 
  v_validationresult  := 0;
  :ValidationResult := v_validationresult;
  :Message := v_message;
  --ErrorCode := v_errorCode;
  --ErrorMessage := v_errorMessage;  
  RETURN -1;


END;