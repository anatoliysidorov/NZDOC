declare
    v_Recordid Integer;
    v_Recordid2 Integer;
    v_CaseId Integer;
    v_col_CaseId nvarchar2(255);
    v_PriorityCase Integer;
    v_ProcedureId Integer;
    v_Owner nvarchar2(255);
    v_TaskOwner nvarchar2(255);
    v_Summary nvarchar2(255);
    v_ActivityCode nvarchar2(255);
    v_WorkflowCode nvarchar2(255);
    v_OwnerWorkBasketId Integer;
	
    v_ResolveBy date;

    v_Result Integer;
    v_ErrorCode Number;
    v_ErrorMessage nvarchar2(255);
    v_affectedRows number;
    v_CaseSysTypeId Integer;
    v_Description nclob;
    v_tmsg nvarchar2(255);
    v_tec number;
    v_draft number;

begin
    --COMMON ATTRIBUTES
    v_col_CaseId := null;
    v_Owner := :Owner;
    v_PriorityCase := :PriorityCase;
    v_Summary := :Summary;
    v_ResolveBy := :ResolveBy;
    v_CaseSysTypeId := :CaseSysTypeId;
    v_ProcedureId := :ProcedureId;
    v_Description := :Description;
    v_OwnerWorkBasketId := :OwnerWorkBasketId;
    v_draft := :Draft;
    :ErrorCode := 0;
    :ErrorMessage := null;
	
    --CREATE CASE
    v_CaseId := f_DCM_createCaseFn2 (affectedRows => v_affectedRows, CaseSysTypeId => v_CaseSysTypeId, Description => v_Description, Draft => v_draft, Owner => v_Owner, PriorityCase => v_PriorityCase, ProcedureId => v_ProcedureId,
                                    recordId => v_RecordId, ResolveBy => v_ResolveBy, Summary => v_Summary, TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT, OwnerWorkBasketId=> v_OwnerWorkBasketId);
	
    --GET IDENTIFIERS FOR CREATED CASE
    v_CaseId := v_Recordid;
    :recordid := v_Recordid;

   --CREATE HISTORY RECORD FOR NEW CASE
   v_Result := f_DCM_createCaseHistory(CaseId => v_CaseId, MessageCode => 'CaseCreated', IsSystem => 0);
   
   --CREATE WORK ITEM FOR CASE
   v_Result := f_CSW_createWorkitem2(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, Owner => v_Owner, ProcedureId => v_ProcedureId);
   
   --GENERATE CASE ID FOR BUSINESS REFERENCE
   v_Result := f_DCM_generateCaseId2(CaseId => v_CaseId, CaseTitle => v_col_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
   :CaseId := v_col_CaseId;   

   --COPY CASE STATE INITIATION RECORDS TO MAP_CASESTATEINITIATION TABLE FOR CREATED CASE
   v_Result := f_DCM_copyCaseStateInit (CaseId => v_CaseId);
   
   --COPY CASE EVENTS
   v_Result := f_DCM_copyCaseEvent(CaseId => v_CaseId);
   
   --COPY CASE EVENT PARAMETERS
   v_Result := f_DCM_copyCaseRuleParam(CaseId => v_CaseId);

   --CREATE TASKS FOR CASE FROM PROCEDURE (TASK HIERARCHY CONFIGURATION)
   v_TaskOwner := null;
   v_Result := f_DCM_CopyTask (affectedRows => v_affectedRows, CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner, prefix => 'TASK-',
                               ProcedureId => v_ProcedureId, recordId => v_RecordId2, TOKEN_USERACCESSSUBJECT => :TOKEN_USERACCESSSUBJECT);
   if nvl(v_ErrorCode,0) not in (0,200) then
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    return -1;
   end if;
   
   --CREATE WORK ITEM FOR EACH CREATED ABOVE TASK
   v_ActivityCode := f_dcm_getTaskNewState();
   v_WorkflowCode := :TOKEN_DOMAIN || '_' || f_DCM_getTaskWorkflowCodeFn();
   
   begin
     for task_rec in (
     select col_id from tbl_task where col_casetask = v_CaseId)
     loop
       v_Result := f_TSKW_createWorkitem2 (ActivityCode => v_ActivityCode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                           TaskId => task_rec.col_id,  WorkflowCode => v_WorkflowCode);
       v_Result := f_DCM_addTaskDateEventList(TaskId => task_rec.col_id, state => v_ActivityCode);
       v_Result := f_DCM_createTaskHistory (IsSystem => 0, MessageCode => 'TaskCreatedInState', TaskId => task_rec.col_id);

       -- CREATE A TASK EXT RECORD FOR EACH TASK
       INSERT INTO tbl_taskext (COL_TASKEXTTASK)
         VALUES (task_rec.col_id);
		
     end loop;
   end;

  --COPY SLA EVENTS AND SLA ACTIONS
  v_result := f_DCM_copySlaEvent(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;

  --COPY PARTICIPANTS TO CASE PARTIES FOR THE CASE
  v_result := f_DCM_CopyParticipant(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;
  
  --CREATE TASK STATE INITIATION ITEMS
  v_result := f_DCM_CopyTaskStateInit(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;

  --CREATE TASK DEPENDENCY ITEMS
  v_result := f_DCM_CopyTaskDependency(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;
  
  --CREATE TASK EVENT ITEMS
  v_result := f_DCM_CopyTaskEvent(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;
  
  --CREATE AUTO RULE PARAMETERS
  v_result := f_DCM_CopyRuleParameter(CaseId => v_CaseId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, owner => v_TaskOwner);
  if nvl(v_ErrorCode,0) not in (0,200) then
   :ErrorCode := v_ErrorCode;
   :ErrorMessage := v_ErrorMessage;
   return -1;
  end if;

   --CREATE CASE DATE EVENTS 'DATE_CASE_CREATED' AND 'DATE_CASE_MODIFIED'
   v_Result := f_DCM_addCaseDateEventList2(CaseId => v_CaseId);
                                      
end;