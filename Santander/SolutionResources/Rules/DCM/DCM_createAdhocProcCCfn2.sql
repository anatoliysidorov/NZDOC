declare
  v_result        number;
  v_TaskId        Integer;
  v_WorkItemId    Integer;
  v_TaskIdCustom  Integer;
  v_CaseId        Integer;
  v_TransactionId Integer;
  v_BusTaskId     nvarchar2(255);
  v_affectedRows  integer;
  v_ErrorCode     number;
  v_ErrorMessage  nvarchar2(255);
  v_sourceid      Integer;
  v_parentid      Integer;
  v_parentid2     Integer;
  v_depth         Integer;
  v_TokenDomain   nvarchar2(255);
  v_workflow      nvarchar2(255);
  v_activitycode  nvarchar2(255);
  v_workflowcode  nvarchar2(255);
  v_stateClosed   nvarchar2(255);
  v_stateNew      nvarchar2(255);
  v_stateStarted  nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateConfigId Integer;
  v_createdby     nvarchar2(255);
  v_createddate   date;
  v_modifiedby    nvarchar2(255);
  v_modifieddate  date;
  v_owner         nvarchar2(255);
  v_rootname    nvarchar2(255);
  v_name          nvarchar2(255);
  v_description   nclob;
  v_required      number;
  v_leaf          Integer;
  v_icon          nvarchar2(255);
  v_iconcls       nvarchar2(255);
  v_taskorder     Integer;
  v_enabled       number;
  v_hoursworked   number;
  v_systemtype    nvarchar2(255);
  v_DateAssigned  date;
  v_prefix        nvarchar2(255);
  v_workbasketid  Integer;
  v_position      nvarchar2(255);
  v_attachedprocId  Integer;
  v_attachedproccode nvarchar2(255);
  v_count         Integer;
  v_adhocTaskTypeId Integer;
  v_adhocTaskTypeCode nvarchar2(255);
  v_adhocExecMehodId Integer;
  v_deleteroot number;
  v_customdataprocessor nvarchar2(255);
  v_TaskExtId Integer;
  v_Input nclob;
  v_draft number;
  v_DebugSession nvarchar2(255);
  v_msg          NCLOB; 
  v_isCaseInCache Integer;
  --------------------------------
  v_preventDocFolderCreate number;
  v_CaseFrom nvarchar2(255);
  v_DocumentsName NVARCHAR2(255);
  v_DocumentsURL NVARCHAR2(255);
  V_SV_URL NVARCHAR2(255);
  V_SV_FILENAME NVARCHAR2(255);
  v_parentfolder_id number;

  CURSOR urls( sv_urls IN NCLOB)
  IS
    SELECT * FROM TABLE(Asf_split(sv_urls, '|||'));
  CURSOR file_names( sv_names IN NCLOB)
  IS
    SELECT * FROM TABLE(Asf_split(sv_names, '|||'));

begin
  v_CaseId := :CaseId;
  v_createdby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_owner := v_createdby;
  v_sourceid := :sourceid;
  v_rootname := :RootName;
  v_deleteroot := :DeleteRoot;
  v_description := :Description;
  v_required := 0;
  v_leaf := 1;
  v_icon := null;
  v_iconcls := v_icon;
  v_enabled := 1;
  v_hoursworked := null;
  v_systemtype := null;
  v_DateAssigned := v_createddate;
  v_prefix := 'TASK';
  v_workbasketid := :WorkbasketId;
  v_position := :Position;
  v_attachedproccode := :AttachedProcedure;
  v_attachedproccode := :AttachedProcCode;
  v_Input := :Input;
  v_TaskExtId :=NULL;
  v_WorkItemId:=NULL;  
  
  if v_Input is null then
    v_Input := '<CustomData><Attributes></Attributes></CustomData>';
  end if;
  
  v_msg := '';
  v_draft := :Draft;
  v_TransactionId := null;
  
  :ErrorCode := 0;
  :ErrorMessage := null;
  
  v_preventDocFolderCreate := NVL(:preventDocFolderCreate, 0);
  v_CaseFrom := NVL(:CaseFrom, 'main'); --options are either 'main' or 'portal'

  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();

  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateClosed := f_dcm_getTaskClosedState();

  v_isCaseInCache := f_DCM_isCaseInCache(v_CaseId);

  --LOG BASIC INFO
  IF v_isCaseInCache = 1 THEN
    v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: Case is in cache');
  ELSE
    v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: Case is not in cache');
  END IF; 


  --IF SOURCE TASK IS NOT DEFINED APPEND ADHOC TASK TO CASE ROOT TASK
  if v_sourceid is null then
    v_position := 'append';
  end if;

  --FIND SOURCE TASK IF NOT DEFINED
  if v_sourceid is null then
    begin
      select col_id into v_sourceid from tbl_taskcc where col_casecctaskcc = v_CaseId and nvl(col_parentidcc,0) = 0;
      exception
      when NO_DATA_FOUND then
        v_sourceid := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Source task not found';
        ErrorCode := v_ErrorCode;
        ErrorMessage := v_ErrorMessage;
        v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
        GOTO cleanup;
    end;
  end if;

  if v_attachedprocId is null and v_attachedproccode is not null then
    begin
      select col_id into v_attachedprocId from tbl_procedure where lower(col_code ) = lower(v_attachedproccode);
      exception
      when NO_DATA_FOUND then
        v_attachedprocId := null;
    end;
  end if;

  if v_rootname is null then
    begin
      select col_name into v_rootname from tbl_procedure where col_id = v_attachedprocId;
      exception
      when NO_DATA_FOUND then
        v_rootname := null;
    end;
  end if;

  begin
    select col_id, col_casecctaskcc, col_depth, col_id
      into v_TaskId, v_CaseId, v_depth, v_parentid
      from tbl_taskcc
      where col_id = v_sourceId;
    exception
      when NO_DATA_FOUND then
        v_TaskId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Source task not found';
        ErrorCode := v_ErrorCode;
        ErrorMessage := v_ErrorMessage;
        v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
        GOTO cleanup;
  end;

  begin
    select col_id into v_adhocTaskTypeId from tbl_dict_tasksystype where lower(col_code) = 'adhoc';
    exception
      when NO_DATA_FOUND then
        v_adhocTaskTypeId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Adhoc task type not found';
        ErrorCode := v_ErrorCode;
        ErrorMessage := v_ErrorMessage;
        v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
        GOTO cleanup;
  end;

  begin
    select col_roottasktypecode into v_adhocTaskTypeCode from tbl_procedure where col_id = v_attachedprocId;
    exception
    when NO_DATA_FOUND then
    v_adhocTaskTypeCode := null;
  end;
  
  if v_adhocTaskTypeCode is not null then
    begin
      select col_id into v_result from tbl_dict_tasksystype where lower(col_code) = lower(v_adhocTaskTypeCode);
      exception
      when NO_DATA_FOUND then
      v_result := null;
    end;
    if v_result is not null then
      v_adhocTaskTypeId := v_result;
    end if;
  end if;

  begin
    select col_id into v_adhocExecMehodId from tbl_dict_executionmethod where lower(col_code) = 'manual';
    exception
      when NO_DATA_FOUND then
        v_adhocExecMehodId := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Adhoc execution method not found';
        ErrorCode := v_ErrorCode;
        ErrorMessage := v_ErrorMessage;
        v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
        GOTO cleanup;
  end;

  if v_position is null then
    v_position := 'append';
  end if;

  if v_position = 'append' then
    begin
      select max(col_taskorder) + 1
        into v_taskorder
        from tbl_taskcc
        where col_parentidcc = v_sourceId
        and col_casecctaskcc = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Parent task not found (v_position = ''append'')';
          ErrorCode := v_ErrorCode;
          ErrorMessage := v_ErrorMessage;
          v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
          GOTO cleanup;
    end;
    if (v_taskorder is null or v_taskorder = 0) then
      v_taskorder := 1;
    end if;
    v_depth := v_depth + 1;
  elsif v_position = 'insert_before' then
    begin
      select col_parentidcc, col_taskorder
        into v_parentid, v_taskorder
        from tbl_taskcc
        where col_id = v_sourceId
        and col_casecctaskcc = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Source task not found (v_position = ''insert_before'')';
          ErrorCode := v_ErrorCode;
          ErrorMessage := v_ErrorMessage;
          v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
          GOTO cleanup;
    end;
  elsif v_position = 'insert_after' then
    begin
      select col_parentidcc, col_taskorder + 1
        into v_parentid, v_taskorder
        from tbl_taskcc
        where col_id = v_sourceId
        and col_casecctaskcc = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_taskorder := null;
          v_ErrorCode := 101;
          v_ErrorMessage := 'Source task not found (v_position = ''insert_after'')';
          ErrorCode := v_ErrorCode;
          ErrorMessage := v_ErrorMessage;
          v_msg := f_UTIL_addToMessage(originalMsg => v_msg, newMsg => 'INFO: '||v_ErrorMessage);
          GOTO cleanup;
    end;
    update tbl_taskcc set col_taskorder = col_taskorder + 1 where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceId) and col_taskorder > v_taskorder;
  end if;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => null, ProcedureId => v_attachedprocId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn begin',
                                   Message => 'Adhoc procedure ' || v_attachedproccode || ' is about to be created and attached to case ' || to_char(v_CaseId), Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  for rec in (select col_id, col_parentttid, col_description, col_name, col_depth, col_leaf, 
                     col_icon, col_iconcls, col_taskorder,
                     col_tasktmpldict_tasksystype, col_execmethodtasktemplate, col_processorcode
            from tbl_tasktemplate
            where col_proceduretasktemplate = v_attachedprocId
            order by col_parentttid, col_taskorder)
  LOOP

    if v_deleteroot = 1 and lower(rec.col_name) = 'root' then
      continue;
    end if;

    v_name:=NULL;
    IF rec.col_name IS NOT NULL THEN
      IF lower(rec.col_name) <> 'root' THEN
        v_name := rec.col_name;
      ELSE
        v_name := v_rootname;
      END IF;
    END IF;

    INSERT INTO tbl_taskcc 
           (col_createdby, col_createddate, col_modifiedby, col_modifieddate,
            col_owner, col_id2, col_parentidcc, 
            col_description, 
            col_name,
            col_required, col_depth, col_leaf, col_icon, col_iconcls,
            col_taskorder, col_casecctaskcc, col_enabled, col_hoursworked,
            col_systemtype2, col_DateAssigned,  
            col_taskccdict_tasksystype,
            col_taskccdict_executionmtd, 
            col_processorname, col_taskccppl_workbasket,
            col_taskccprocedure)
    VALUES
          (v_createdby, v_createddate, v_modifiedby, v_modifieddate, 
           v_owner, rec.col_id, v_parentid,
          (CASE 
            WHEN v_description IS NOT NULL THEN v_description 
            ELSE rec.col_description 
           END), 
           v_name, 
           v_required, rec.col_depth + v_depth, rec.col_leaf, rec.col_icon, rec.col_iconcls, 
           rec.col_taskorder + v_taskorder - 1,  v_CaseId, v_enabled, v_hoursworked, 
           v_systemtype, v_DateAssigned, 
           (CASE
            WHEN lower(rec.col_name) = 'root' THEN v_adhocTaskTypeId
            ELSE rec.col_tasktmpldict_tasksystype
           END), 
           (CASE
            WHEN lower(rec.col_name) = 'root' THEN v_adhocExecMehodId
            ELSE rec.col_execmethodtasktemplate
           END), 
           rec.col_processorcode, v_workbasketid, 
           v_attachedprocId) RETURNING col_id into v_TaskId;

    v_msg := f_UTIL_addToMessage(
     originalMsg => v_msg, 
     newMsg => 'INFO: created new Task with ID ' || TO_CHAR(v_TaskId)
    );

    --------------------------------------------------------------------------------------------------
    
    if v_TransactionId is null then
      v_TransactionId := v_TaskId;
    end if;

    --------------------------------------------------------------------------------------------------

    update tbl_taskcc tsk3
    set col_parentidcc =
    (select tsk.col_id
      from tbl_taskcc tsk2
      inner join tbl_tasktemplate tt2 on tsk2.col_id2 = tt2.col_id
      inner join tbl_tasktemplate tt on tt2.col_parentttid = tt.col_id
      inner join tbl_taskcc tsk on tt.col_id = tsk.col_id2
      where tsk2.col_id = v_TaskId and tsk2.col_transactionid = v_TransactionId and tsk.col_transactionid = v_TransactionId
        and tsk3.col_id = tsk2.col_id)
      where tsk3.col_id = v_TaskId;

    -----------------------------------------------------------------------------------------------------

    --SET TASK INFORMATION
    v_result := f_DCM_generateTaskNameCC(TaskId => v_TaskId);
    v_result := f_DCM_generateTaskCCId(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, 
                                       TaskId => v_TaskId, TaskTitle => v_BusTaskId);

    UPDATE tbl_taskcc 
    SET col_taskid = v_BusTaskId,
        col_transactionid = v_TransactionId
    WHERE col_id = v_TaskId;

    begin
      select tst.col_stateconfigtasksystype into v_stateConfigId 
      from tbl_taskcc tsk 
      inner join tbl_dict_tasksystype tst on tsk.col_taskccdict_tasksystype = tst.col_id 
      where tsk.col_id = v_TaskId;
    exception
      when NO_DATA_FOUND then
      v_stateConfigId := null;
    end;

    v_stateAssigned := f_DCM_getTaskAssignedState2(StateConfigId => v_stateConfigId);
    v_stateStarted := f_DCM_getTaskStartedState2(StateConfigId => v_StateConfigId);
    v_stateNew := f_DCM_getTaskNewState2(StateConfigId => v_stateConfigId);

    --CREATE ACCOMPANYING WORKITEM FOR THE TASK
    if (lower(rec.col_name) = 'root') and (v_workbasketid is not null) then
      v_activitycode := v_stateAssigned;
    elsif (lower(rec.col_name) = 'root') and (v_workbasketid is null) then
      v_activitycode := v_stateStarted;
    else
      v_activitycode := v_stateNew;
    end if;

    v_workflowcode := v_TokenDomain || '_' || v_workflow;
    v_result := f_TSKW_createWorkitemCC(AccessSubjectCode => v_createdby, ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                       Owner => v_owner, TaskId => v_TaskId, TOKEN_USERACCESSSUBJECT => v_createdby, WorkflowCode => v_workflowcode);

     BEGIN
       SELECT  col_tw_workitemcctaskcc INTO  v_WorkItemId
       FROM tbl_taskcc     
       where col_id = v_TaskId;
        exception
        when NO_DATA_FOUND THEN
        v_msg := f_UTIL_addToMessage(
         originalMsg => v_msg, 
         newMsg => 'INFO: workitem for Task with ID ' || TO_CHAR(v_TaskId)|| ' not created. ErrorMessage is: '||v_ErrorMessage
        );
     END;

     IF v_WorkItemId IS NOT NULL THEN
        v_msg := f_UTIL_addToMessage(
         originalMsg => v_msg, 
         newMsg => 'INFO: workitem for Task with ID ' || TO_CHAR(v_TaskId)|| ' was created. WI ID is: '||TO_CHAR(v_WorkItemId)
        );
     END IF;


    v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_CREATED', TaskId => v_TaskId);
    v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_MODIFIED', TaskId => v_TaskId);

    if lower(rec.col_name) = 'root' then
      v_result := f_DCM_copyTaskCCStateInitTask(owner => v_owner, TaskId => v_TaskId);
    else
      v_result := f_DCM_copyTaskCCStateInitTmpl(owner => v_owner, TaskId => v_TaskId);
    end if;    

    -- CREATE A TASK EXT RECORD FOR ATTACHED PROCEDURE
    begin
      select col_customdataprocessor into v_customdataprocessor 
      from tbl_procedure 
      where col_id = v_attachedprocId;
      exception
      when NO_DATA_FOUND then
      v_customdataprocessor := null;
    end;

    --set out param
    --why?
    TaskId := v_TaskId;

    if v_customdataprocessor is null and v_TaskExtId is null then
      update tbl_taskcc set col_draft = v_draft where col_id = v_TaskId;
      
      insert into tbl_taskextcc (col_taskextcctaskcc) 
      values (v_TaskId) RETURNING col_id INTO v_TaskExtId;
      
    elsif v_customdataprocessor is not null and v_TaskExtId is null then
      update tbl_taskcc set col_draft = v_draft where col_id = v_TaskId;

      v_TaskExtId := f_dcm_invokeCustomDataProc(Input => v_Input, ProcessorName => v_customdataprocessor, TaskId => v_TaskId);      
      v_TaskIdCustom:= v_TaskId;
    end if;
   
    --ADD HISTORY RECORD FOR TASK    
    v_result := f_HIST_createHistoryFn(
      AdditionalInfo => v_msg,  
      IsSystem=>0, 
      Message=> NULL,
      MessageCode => 'TaskInjected', 
      TargetID => v_TaskId, 
      TargetType=>'TASK'
    );
    
    v_msg := f_UTIL_addToMessage(originalMsg => '', newMsg => '');
  END LOOP;
  
  if v_TaskIdCustom is not null then
    update tbl_taskcc set col_taskorder = (select max(col_taskorder) + 1 from tbl_taskcc where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_TaskIdCustom)) where col_id = v_TaskIdCustom;
  end if;

  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after tasks created',
                                   Message => 'Adhoc procedure ' || v_attachedproccode || ' tasks are created and attached to case ' || to_char(v_CaseId), Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  if (v_position = 'append') then
    update tbl_taskcc tsk set col_parentidcc = v_sourceid where col_parentidcc is null and col_transactionid = v_TransactionId;
  elsif v_position = 'insert_before' or (v_position = 'insert_after') then
    update tbl_taskcc tsk set col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceid) where col_parentidcc is null and col_transactionid = v_TransactionId;
  end if;
  if (v_position = 'insert_before') then
    select max(col_taskorder) into v_count from tbl_taskcc where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceId) and col_transactionid = v_TransactionId;
    update tbl_taskcc set col_taskorder = col_taskorder + 1 where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceId) and nvl(col_transactionid,0) <> v_TransactionId and col_taskorder >= v_taskorder;
  elsif v_position = 'insert_after' then
    select max(col_taskorder) into v_count from tbl_taskcc where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceId) and col_transactionid = v_TransactionId;
    update tbl_taskcc set col_taskorder = col_taskorder + 1
    where col_parentidcc = (select col_parentidcc from tbl_taskcc where col_id = v_sourceId) and col_id <> v_sourceid and nvl(col_transactionid,0) <> v_TransactionId and col_taskorder >= v_taskorder;
  end if;

  v_result := f_DCM_copySlaEventCCAdhocProc(Transactionid => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after SLA events copied',
                                   Message => 'SLA events are copied to adhoc procedure ' || v_attachedproccode, Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  v_result := f_DCM_CopyTaskDepCCAdhocProc(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after task dependencies copied',
                                   Message => 'Task dependencies are copied to adhoc procedure ' || v_attachedproccode, Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  v_result := f_DCM_CopyTaskEventCCAdhocPrc(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after taskevents copied',
                                   Message => 'Task events are copied to adhoc procedure ' || v_attachedproccode, Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);
  
  v_result := f_DCM_CopyRuleParamCCAdhocPrc(TransactionId => v_TransactionId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn after rule parameters copied',
                                   Message => 'Rule parameters are copied to adhoc procedure ' || v_attachedproccode, Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  v_parentid2 := -1;
  for rec in (select sys_connect_by_path(col_id, '/') as Path, col_parentidcc as col_parentid, col_id, col_taskorder
              from tbl_taskcc
              start with col_parentidcc = v_parentid
              connect by prior col_id =  col_parentidcc
              order by col_parentidcc, col_taskorder, col_id)
  loop
    if rec.col_parentid <> v_parentid2 then
      v_parentid2 := rec.col_parentid;
      v_count := 1;
    end if;
    update tbl_taskcc set col_taskorder = v_count where col_id = rec.col_id;
    v_count := v_count + 1;
  end loop;

  --ADD DOCUMENTS
  IF v_preventDocFolderCreate = 0 THEN
    V_Parentfolder_Id := f_DOC_getDefaultDocFolder(CaseId => v_CaseId, DocFolderType => v_CaseFrom);
    if DocumentsURLs IS NOT NULL AND DocumentsNames IS NOT NULL THEN
      OPEN urls(DocumentsURLs);
      OPEN file_names(DocumentsNames);
      LOOP
        FETCH urls INTO v_sv_url;
        FETCH file_names INTO v_sv_filename;
        EXIT
        WHEN urls%NOTFOUND;
        BEGIN
          v_Result      := f_doc_adddocfn(Name => v_sv_filename,
                                          Description => null,
                                          Url => v_sv_url,
                                          ScanLocation => null,
                                          DocId => v_result,
                                          DocTypeId => null,
                                          FolderId =>  V_Parentfolder_Id,
                                          CaseId => v_caseid,
                                          CaseTypeId => null,
                                          ErrorCode => v_ErrorCode,
                                          ErrorMessage => v_ErrorMessage);
          EXCEPTION
          WHEN OTHERS THEN
            ErrorCode      := v_ErrorCode;
            IF(v_ErrorMessage = '')THEN
              v_ErrorMessage := 'During insert of the following records there were errors: ';
            END IF;
            ErrorMessage := v_ErrorMessage;

            v_msg := f_UTIL_addToMessage(
              originalMsg => v_msg, 
              newMsg => 'INFO: Add documents. ' || v_ErrorMessage
            );
        END;
        ErrorCode := v_ErrorCode;
        ErrorMessage := v_ErrorMessage;
        if nvl(v_ErrorCode,0) not in (0,200) THEN
            CLOSE urls;
            CLOSE file_names;
            v_msg := f_UTIL_addToMessage(
              originalMsg => v_msg, 
              newMsg => 'INFO: Add documents. ' || v_ErrorMessage
            );
           GOTO cleanup;
        end if;
      END LOOP;
      CLOSE urls;
      CLOSE file_names;
    end if;
  END IF;

  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => null, ProcedureId => v_attachedprocId);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_insertAdhocProcPosFn end',
                                   Message => 'Adhoc procedure ' || v_attachedproccode || ' is created and attached to case', Rule => 'DCM_insertAdhocProcPosFn', TaskId => null);

  ErrorCode := 0;
  ErrorMessage := 'Success';

   RETURN 0;
   
  --ERROR BLOCK
  <<cleanup>>  
  v_result := f_HIST_createHistoryFn(
    AdditionalInfo => v_msg,  
    IsSystem=>0, 
    Message=> 'ERROR BLOCK',
    MessageCode => NULL, 
    TargetID => v_CaseId, 
    TargetType=>'CASE'
  );
  RETURN -1;

end;
