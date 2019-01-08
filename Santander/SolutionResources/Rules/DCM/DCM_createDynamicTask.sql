declare
 v_Result        number;
 v_CaseId        number;
 v_affectedRows  integer;
 v_ErrorCode     number;
 v_ErrorMessage  nvarchar2(255);
 v_count        integer;
 v_TaskId       integer;
 v_parentid     integer;
 v_owner        nvarchar2(255);
 v_GenTaskId    nvarchar2(255);
 v_createdby    nvarchar2(255);
 v_createddate  date;
 v_modifiedby   nvarchar2(255);
 v_modifieddate date;
 v_pparentid    integer;
 v_name         nvarchar2(255);
 v_description  nclob;
 v_required     number;
 v_depth        integer;
 v_leaf         integer;
 v_taskorder    integer;
 v_icon         nvarchar2(255);
 v_iconcls      nvarchar2(255);
 v_workflowcode nvarchar2(255);
 v_activitycode nvarchar2(255);
 v_SystemTypeId Integer;
 v_TokenDomain  nvarchar2(255);
 v_workflow     nvarchar2(255);
 v_activity     nvarchar2(255);
 v_assignedactivity nvarchar2(255);
 v_workbasketid integer;
 v_sessionid    nvarchar2(255);
 v_ExecMethodId Integer;

begin
  v_CaseId := :CaseId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_pparentid := :parentid;
  v_name := :name;
  v_description := :description;
  v_required := :required;
  v_leaf := :leaf;
  v_icon := :icon;
  v_iconcls := v_icon;
  v_SystemTypeId := :SystemTypeId;
  v_workbasketid := :WorkbasketId;
  v_sessionid := :SessionId;

  --FIND TOKEN_DOMAIN
  v_TokenDomain := f_UTIL_getDomainFn();
  v_workflow := f_DCM_getTaskWorkflowCodeFn();

  v_activity := f_dcm_getTaskNewState();
  v_assignedactivity := f_dcm_getTaskAssignedState();

  -- GET THE ORDER NUMBER FOR THE TASK
  begin
    select col_id, col_depth
      into v_parentid, v_depth
      from tbl_dynamictask
      where col_casedynamictask = v_CaseId
           and col_id = v_pparentid;
    exception
      when NO_DATA_FOUND then
        v_parentId := 0;
        v_depth := 0;
  end;
  
  begin
    select col_id into v_ExecMethodId from tbl_dict_executionmethod where lower(col_code) = 'manual';
    exception
      when NO_DATA_FOUND then
        v_ExecMethodId := null;
  end;

  v_taskorder := 1;
  if v_parentid = 0 then
    v_count := 0;
  else
    select count(*)
      into v_count
      from tbl_dynamictask
      where col_dynamictaskparentid = v_parentid;
  end if;

  if (v_count = 0) then
    v_taskorder := 1;
  else
    begin
      select max (col_taskorder) + 1
        into v_taskorder
        from tbl_dynamictask
        where col_dynamictaskparentid = v_parentid;
      exception
        when NO_DATA_FOUND then
          v_taskorder := 1;
    end;
  end if;

  -- CREATE DYNAMIC TASK
  insert into tbl_dynamictask
              (col_createdby,
               col_createddate,
               col_modifiedby,
               col_modifieddate,
               col_owner,
               col_dynamictaskparentid,
               col_description,
               col_name,
               col_required,
               col_depth,
               col_leaf,
               col_icon,
               col_iconcls,
               col_taskorder,
               col_casedynamictask,
               col_dynamictasktasksystype,
               col_dynamictaskexecmethod,
               col_dynamictaskppl_workbasket,
               col_sessionid)
    values    (v_createdby,
               v_createddate,
               v_modifiedby,
               v_modifieddate,
               v_owner,
               v_parentid,
               v_description,
               v_name,
               v_required,
               v_depth + 1,
               v_leaf,
               v_icon,
               v_iconcls,
               v_taskorder,
               v_CaseId,
               v_SystemTypeId,
               v_ExecMethodId,
               v_workbasketid,
               v_sessionid);

  select gen_tbl_dynamictask.currval into v_TaskId from dual;

  v_Result := f_DCM_genDynamicTaskId (affectedRows => v_affectedRows, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                  prefix => :prefix, recordid => v_TaskId, taskid => v_GenTaskId);
  
  --CREATE ACCOMPANYING WORKITEM FOR THE TASK
  if v_workbasketid is not null then
    v_activity := v_assignedactivity;
  end if;
  v_activitycode := v_activity;
  v_workflowcode := v_TokenDomain || '_' || v_workflow;
  v_Result := f_TSKW_createDynamicWI (AccessSubjectCode => v_createdby, ActivityCode => v_activitycode, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                   Owner => v_owner, TaskId => v_TaskId, TOKEN_USERACCESSSUBJECT => SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'), WorkflowCode => v_workflowcode);
  :TaskId := v_TaskId;

end;