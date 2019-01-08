DECLARE  
  v_Recordid2         INTEGER;
  v_CaseId            INTEGER;
  v_CaseTitle         NVARCHAR2(255);
  v_PriorityCase      INTEGER;
  v_ProcedureId       INTEGER;
  v_Owner             NVARCHAR2(255);
  v_TaskOwner         NVARCHAR2(255);
  v_Summary           NVARCHAR2(255);
  v_ActivityCode      NVARCHAR2(255);
  v_WorkflowCode      NVARCHAR2(255);
  v_userAXS           NVARCHAR2(255);
  v_OwnerWorkBasketId INTEGER;
  v_ResolveBy       DATE;
  v_Result          INTEGER;
  v_IsValid         INTEGER;
  v_ErrorCode       NUMBER;
  v_ErrorMessage    NVARCHAR2(255);
  v_affectedRows    NUMBER;
  v_CaseSysTypeId   INTEGER;
  v_Description     NCLOB;
  v_tmsg            NVARCHAR2(255);
  v_tec             NUMBER;
  v_draft           NUMBER;
  v_DebugSession    NVARCHAR2(255);
  v_stateconfigid     NUMBER;
  v_workitemId        INTEGER;
  v_col_DateAssigned  DATE;
  
  --milestone data
  v_stateMSConfigId   NUMBER;
  v_StateId           NUMBER;
  v_StateActivity     NVARCHAR2(255); 
  v_dateEventValue    DATE;   
  v_sysStateId        INTEGER;
  v_sysStateActivity NVARCHAR2(255);

  --SLA 
  v_GoalSLADT    DATE;
  v_DlineSLADT   DATE;

BEGIN

  --COMMON ATTRIBUTES
  v_CaseTitle     := NULL;
  v_userAXS       := NVL(:TOKEN_USERACCESSSUBJECT, SYS_CONTEXT('CLIENTCONTEXT', 'AccessSubject'));  
  v_Owner         := :Owner;
  v_PriorityCase  := :PriorityCase;
  v_Summary       := :Summary;
  v_ResolveBy     := :ResolveBy;
  v_CaseSysTypeId   := :CaseSysTypeId;
  v_ProcedureId     := :ProcedureId;
  v_Description     := :Description;
  v_OwnerWorkBasketId := :OwnerWorkBasketId;
  v_draft             := :Draft;
  
  v_StateId         := NULL;
  v_StateActivity   := NULL;
  v_stateMSConfigId := NULL;  
	
  -- =========================================================
  --
  -- CACHE USING START
  -- 
  -- =========================================================

  --CREATE CASE INSIDE A CACHE
  v_dateEventValue := SYSDATE;
  SELECT gen_tbl_Case.NEXTVAL INTO v_CaseId FROM dual;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon begin', Message => 'Case is about to be created', Rule => 'DCM_createCaseCommon', TaskId => null);

  --GET A DATA FROM MILESTONE CONFIGURATION
  BEGIN
    SELECT st.COL_ID, st.COL_ACTIVITY, sc.COL_ID, st.COL_STATECASESTATE, cst.COL_ACTIVITY
    INTO v_StateId, v_StateActivity, v_stateMSConfigId, v_sysStateId, v_sysStateActivity          
    FROM  TBL_DICT_STATE st
    INNER JOIN TBL_DICT_CASESTATE cst ON st.COL_STATECASESTATE=cst.COL_ID
    INNER JOIN TBL_DICT_STATECONFIG sc ON sc.COL_ID=st.COL_STATESTATECONFIG
    WHERE cst.COL_ISSTART=1  
          AND sc.COL_CASESYSTYPESTATECONFIG = v_CaseSysTypeId
          AND sc.COL_ISCURRENT=1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_StateId           := NULL;
         v_StateActivity     := NULL;
         v_stateMSConfigId   := NULL;
         v_sysStateId        := NULL;
         v_sysStateActivity  := NULL;
      WHEN TOO_MANY_ROWS THEN
         v_StateId           := NULL;
         v_StateActivity     := NULL;
         v_stateMSConfigId   := NULL;
         v_sysStateId        := NULL;
         v_sysStateActivity  := NULL;
      WHEN OTHERS THEN
         v_StateId           := NULL;
         v_StateActivity     := NULL;
         v_stateMSConfigId   := NULL;
         v_sysStateId        := NULL;
         v_sysStateActivity  := NULL;
  END; 

   --GET SLA DATA
   v_GoalSLADT   := NULL;
   v_DlineSLADT  := NULL;
     
   BEGIN
    SELECT 
    (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    is null
    and (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    is null then null
    else v_dateEventValue end) + 
    (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    is not null then
    (select  to_dsinterval(sseg.col_intervalds) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    else to_dsinterval('0 000') end) +
    (case when (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    is not null then
    (select to_yminterval(sseg.col_intervalym) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = v_StateId)
    else to_yminterval('0-0') end),

    (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    is null
    and (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    is null then null
    else v_dateEventValue end) + 
    (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    is not null then
    (select  to_dsinterval(ssed.col_intervalds) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    else to_dsinterval('0 000') end) +
    (case when (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    is not null then
    (select to_yminterval(ssed.col_intervalym) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = v_StateId)
    else to_yminterval('0-0') end)
    
    INTO v_GoalSLADT, v_DlineSLADT FROM DUAL; 
   END;
   
  IF (v_Owner IS NOT NULL) THEN v_col_DateAssigned := SYSDATE;
  ELSE v_col_DateAssigned := NULL;
  END IF;  
    
  --GET WF CODE
  v_WorkflowCode:=  f_UTIL_getDomainFn() || '_' || f_DCM_getCaseWorkflowCodeFn();  

  --CREATE A CASE WORLITEM
  SELECT gen_tbl_CW_Workitem.nextval INTO v_workitemId FROM dual;

  --INSERT A WF DATA
  INSERT INTO TBL_CSCW_WORKITEM(COL_ID, COL_WORKFLOW, COL_ACTIVITY, COL_CW_WORKITEMDICT_CASESTATE, 
                                COL_INSTANCEID, COL_OWNER, COL_CREATEDBY, COL_CREATEDDATE, 
                                COL_INSTANCETYPE, COL_MILESTONEACTIVITY, COL_CWIDICT_STATE)
  VALUES(v_workitemId, v_WorkflowCode, v_sysStateActivity, v_sysStateId, 
         SYS_GUID(), v_userAXS, v_userAXS, SYSDATE,  1, v_StateActivity, v_StateId);

  --INSERT A CASE DATA
  INSERT INTO TBL_CSCASE(COL_ID, COL_CASEID, COL_CREATEDBY, COL_CREATEDDATE, COL_DATEASSIGNED,
                         COL_OWNER, COL_STP_PRIORITYCASE, COL_PROCEDURECASE, COL_CASEDICT_CASESYSTYPE,
                         COL_SUMMARY, COL_RESOLVEBY, COL_CASEPPL_WORKBASKET, COL_DRAFT,
                         COL_ACTIVITY, COL_CASEDICT_CASESTATE, COL_MILESTONEACTIVITY,  COL_CASEDICT_STATE,
                         COL_DATEEVENTVALUE, COL_GOALSLADATETIME,
                         COL_DLINESLADATETIME, COL_CW_WORKITEMCASE, COL_WORKFLOW)

  VALUES(v_CaseId, v_CaseTitle, v_userAXS, SYSDATE, v_col_DateAssigned,
         v_Owner, v_PriorityCase, v_ProcedureId, v_CaseSysTypeId,
         v_Summary, v_ResolveBy, v_OwnerWorkBasketId, v_draft,
         v_sysStateActivity, v_sysStateId, v_StateActivity, v_StateId,
         v_dateEventValue, v_GoalSLADT, v_DlineSLADT, v_workitemId, v_WorkflowCode);

  INSERT INTO TBL_CASEEXT(COL_CASEEXTCASE, COL_DESCRIPTION) VALUES(v_CaseId, v_Description);  

  --CREATE HISTORY RECORD FOR NEW CASE
  v_Result := f_DCM_createCaseHistory(CASEID      => v_CaseId, 
                                      MESSAGECODE => 'CaseCreatedInState', 
                                      ISSYSTEM    => 0);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case history created', Message => 'Case ' || to_char(v_CaseId) || ' history created', Rule => 'DCM_createCaseCommon', TaskId => null);
  
  --GENERATE CASE ID FOR BUSINESS REFERENCE  
  v_Result := f_DCM_generateCaseId2(CaseId        => v_CaseId, 
                                    CaseTitle     => v_CaseTitle, 
                                    ErrorCode     => v_ErrorCode, 
                                    ErrorMessage  => v_ErrorMessage);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case title generated', Message => 'Case ' || to_char(v_CaseId) || ' title ' || v_CaseTitle || ' generated', Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY CASE STATE INITIATION RECORDS TO MAP_CASESTATEINITIATION TABLE FOR CREATED CASE
  v_Result := f_DCM_copyCaseStateInit (CaseId => v_CaseId);

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case state initiation records copied', Message => 'Case ' || to_char(v_CaseId) || ' case state initiation records copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASKS FOR CASE FROM PROCEDURE (TASK HIERARCHY CONFIGURATION)
  v_TaskOwner := null;
  v_Result := f_DCM_CopyTask (affectedRows  => v_affectedRows, 
                              CaseId        => v_CaseId, 
                              ErrorCode     => v_ErrorCode, 
                              ErrorMessage  => v_ErrorMessage, 
                              owner         => v_TaskOwner, 
                              prefix        => 'TASK',
                              ProcedureId   => v_ProcedureId, 
                              recordId      => v_RecordId2, 
                              TOKEN_USERACCESSSUBJECT => v_userAXS);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case tasks from task templates copied', Message => 'Case ' || to_char(v_CaseId) || ' tasks copied from task templates', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE WORK ITEM FOR EACH CREATED ABOVE TASK  
  v_WorkflowCode := :TOKEN_DOMAIN || '_' || f_DCM_getTaskWorkflowCodeFn();
  
  BEGIN
    FOR task_rec IN 
    (
      SELECT COL_ID, COL_TASKDICT_TASKSYSTYPE 
      FROM TBL_CSTASK 
      WHERE COL_CASETASK = v_CaseId
    )
    LOOP

      BEGIN
        SELECT COL_STATECONFIGTASKSYSTYPE INTO v_stateconfigid 
        FROM TBL_DICT_TASKSYSTYPE WHERE col_id = task_rec.COL_TASKDICT_TASKSYSTYPE;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_stateconfigid := null;
      END;

      IF v_stateconfigid IS NULL THEN
        BEGIN
          SELECT COL_ID INTO v_stateconfigid 
          FROM TBL_DICT_STATECONFIG WHERE COL_ISDEFAULT = 1 AND lower(COL_TYPE) = 'task';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN v_stateconfigid := NULL;
          WHEN TOO_MANY_ROWS THEN v_stateconfigid := NULL;
        END;
      END IF;

      v_ACtivityCode := f_dcm_getTaskNewState2(StateConfigId => v_stateconfigid);
      v_Result := f_TSKW_createWorkitem2 (ActivityCode  => v_ActivityCode, 
                                          ErrorCode     => v_ErrorCode, 
                                          ErrorMessage  => v_ErrorMessage,
                                          TaskId        => task_rec.col_id,  
                                          WorkflowCode  => v_WorkflowCode);

      IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

      v_Result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => task_rec.col_id);

      -- CREATE A TASK EXT RECORD FOR EACH TASK
      INSERT INTO TBL_TASKEXT (COL_TASKEXTTASK) VALUES (task_rec.col_id);
		
    END LOOP;
  END;

  --COPY PARTICIPANTS TO CASE PARTIES FOR THE CASE
  v_result := f_DCM_CopyParticipant(CaseId      => v_CaseId, 
                                    ErrorCode     => v_ErrorCode, 
                                    ErrorMessage => v_ErrorMessage);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  --PROCESS EVENTS AFTER CASE CREATION
  v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>NULL,
                                         CASEID=> v_CaseId,
                                         ERRORCODE=>v_errorCode,
                                         ERRORMESSAGE =>v_errorMessage,
                                         EVTMOMENT=>'AFTER',
                                         EVTSTATE=>v_StateActivity,
                                         EVTTYPE=>'ACTION',
                                         ISVALID=>v_IsValid,
                                         STATECONFIGID=>v_stateMSConfigId);

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon task list created', Message => 'Task list created in case ' || to_char(v_CaseId), Rule => 'DCM_createCaseCommon', TaskId => null);

  --COPY SLA EVENTS AND SLA ACTIONS
  v_result := f_DCM_copySlaEvent(CaseId       => v_CaseId, 
                                 ErrorCode    => v_ErrorCode, 
                                 ErrorMessage => v_ErrorMessage);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case SLA events copied', Message => 'Case ' || to_char(v_CaseId) || ' SLA events copied', Rule => 'DCM_createCaseCommon', TaskId => null);  

  --CREATE TASK STATE INITIATION ITEMS
  v_result := f_DCM_CopyTaskStateInit(CaseId        => v_CaseId, 
                                      ErrorCode     => v_ErrorCode, 
                                      ErrorMessage  => v_ErrorMessage, 
                                      owner         => v_TaskOwner);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case tasks state initiation records copied', Message => 'Case ' || to_char(v_CaseId) || ' tasks initiation records copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASK DEPENDENCY ITEMS
  v_result := f_DCM_CopyTaskDependency(CaseId         => v_CaseId, 
                                       ErrorCode      => v_ErrorCode, 
                                       ErrorMessage   => v_ErrorMessage, 
                                       owner          => v_TaskOwner);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task dependencies copied', Message => 'Case ' || to_char(v_CaseId) || ' task dependencies copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE TASK EVENT ITEMS
  v_result := f_DCM_CopyTaskEvent(CaseId        => v_CaseId, 
                                  ErrorCode     => v_ErrorCode, 
                                  ErrorMessage  => v_ErrorMessage, 
                                  owner         => v_TaskOwner);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task events copied', Message => 'Case ' || to_char(v_CaseId) || ' task events copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE AUTO RULE PARAMETERS
  v_result := f_DCM_CopyRuleParameter(CaseId        => v_CaseId, 
                                      ErrorCode     => v_ErrorCode, 
                                      ErrorMessage  => v_ErrorMessage, 
                                      owner         => v_TaskOwner);

  IF NVL(v_ErrorCode,0) NOT IN (0,200) THEN GOTO cleanup; END IF;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case task rule parameters copied', Message => 'Case ' || to_char(v_CaseId) || ' task rule parameters copied', Rule => 'DCM_createCaseCommon', TaskId => null);

  --CREATE CASE DATE EVENTS
  v_result := f_DCM_addCaseMSDateEventList(CASEID       => v_CaseId, 
                                          STATECONFIGID =>v_stateMSConfigId);
    
  --UPDATE CASE FROM CACHE
  v_result := f_DCM_CSCUseCache(CASEID     =>v_CaseId, 
                                DIRECTION  =>'UPDATE_FROM_CACHE', 
                                USEMODE    =>NULL);  
  
  v_result :=f_DCM_CSCleanUpCache();

  -- =========================================================
  --
  -- CACHE USING END
  -- 
  -- =========================================================

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon case related data created', Message => 'Case related data created in case ' || to_char(v_CaseId), Rule => 'DCM_createCaseCommon', TaskId => null);

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => v_CaseSysTypeId, ProcedureId => v_ProcedureId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_createCaseCommon end', Message => 'Case ' || to_char(v_CaseId) || ' is created', Rule => 'DCM_createCaseCommon', TaskId => null);

  --OUTPUT
  :ErrorCode    := 0;
  :ErrorMessage := NULL;  
  :CaseId       := v_CaseTitle;  
  :recordid     := v_CaseId; 
  RETURN 0;

  <<cleanup>>
  IF f_DCM_CSisCaseInCache(v_caseid)=1 THEN v_result :=f_DCM_CSCleanUpCache(); END IF; 
  :ErrorCode     := v_ErrorCode;
  :ErrorMessage  := v_ErrorMessage;
  :CaseId        := v_CaseTitle;  
  :recordid      := v_CaseId; 

  RETURN -1;

END;