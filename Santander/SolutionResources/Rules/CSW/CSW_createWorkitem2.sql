--CREATE CASE WORKITEM
declare
  v_caseid Integer;
  v_casetitle nvarchar2(255);
  v_casetypeid Integer;
  v_casetypecode nvarchar2(255);
  v_casetypename nvarchar2(255);
  v_casetypeprocessorcode nvarchar2(255);
  v_stateconfigid Integer;
  v_stateid Integer;
  v_activitycode nvarchar2(255);
  v_owner nvarchar2(255);
  v_workitemid Integer;
  v_procedureid Integer;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_affectedRows number;
  v_result number;
  
  --custom milestone data  
  v_MSStateId         NUMBER;
  v_MSStateActivity   NVARCHAR2(255);
  
begin

  v_caseid := :CaseId;
  v_owner := :Owner;
  
  v_MSStateId := NULL;
  v_MSStateActivity := NULL;
  
  begin
    select cs.col_casedict_casesystype, cs.col_procedurecase, cs.COL_MILESTONEACTIVITY, cs.COL_CASEDICT_STATE 
    into v_casetypeid, v_procedureid, v_MSStateActivity, v_MSStateId 
    from tbl_case cs
    where cs.col_id = v_caseid;
    exception
      when NO_DATA_FOUND then
        v_casetypeid := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'Case type for case ' || to_char(v_caseid) || ' not found';
        return -1;
  end;
  begin
    select col_code, col_name, col_processorcode, col_stateconfigcasesystype
      into v_casetypecode, v_casetypename, v_casetypeprocessorcode, v_stateconfigid
      from tbl_dict_casesystype
      where col_id = v_casetypeid;
    exception
      when NO_DATA_FOUND then
        v_ErrorCode := 102;
        v_ErrorMessage := 'Case type not found';
        return -1;
  end;
  if v_owner is null then
    v_stateid := f_dcm_getCaseNewStateId2(StateConfigId => v_stateconfigid);
  else
    v_stateid := f_dcm_getCaseInProcessStateId2(StateConfigId => v_stateconfigid);
  end if;
  begin
    insert into tbl_cw_workitem(col_workflow, col_activity, col_cw_workitemdict_casestate, 
                                col_instanceid, col_owner, col_createdby, col_createddate, 
                                col_instancetype, col_MilestoneActivity, col_CWIDICT_State)
    values(f_UTIL_getDomainFn() || '_' || f_DCM_getCaseWorkflowCodeFn(),
           (select col_activity from tbl_dict_casestate where col_id = v_stateid),
           v_stateid, sys_guid(), sys_context('CLIENTCONTEXT', 'AccessSubject'), sys_context('CLIENTCONTEXT', 'AccessSubject'), sysdate, 1,
           v_MSStateActivity, v_MSStateId);
    v_ErrorCode := 0;
    v_ErrorMessage := '';
    select gen_tbl_cw_workitem.currval into v_workItemid from dual;
    update tbl_case
    set col_cw_workitemcase = v_workItemid,
    col_activity = (select col_activity from tbl_dict_casestate where col_id = v_stateid),
    col_workflow = f_UTIL_getDomainFn() || '_' || f_DCM_getCaseWorkflowCodeFn(),
    col_casedict_casestate = v_stateid
    where col_id = v_caseid;
    exception
    when OTHERS then
      v_ErrorCode := 101;
      v_ErrorMessage := substr(sqlerrm, 1, 200);
  end;
  if v_stateconfigid is not null then
    begin
      select col_id into v_procedureid from tbl_procedure where col_proceduredict_casesystype = v_casetypeid and col_procedurecasestate = v_stateid;
      exception
      when NO_DATA_FOUND then
        v_ErrorCode := 102;
        v_ErrorMessage := 'No procedure found for case type ' || to_char(v_casetypeid) || ' and state ' || to_char(v_stateid);
    end;
    if v_procedureid is not null then
      update tbl_case set col_procedurecase = v_procedureid where col_id = v_CaseId;
    end if;
  end if;
  :ProcedureId := v_procedureid;
end;