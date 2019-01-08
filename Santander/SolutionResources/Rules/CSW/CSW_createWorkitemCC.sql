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
begin
  v_caseid := :CaseId;
  v_owner := :Owner;
  begin
    select cs.col_caseccdict_casesystype, col_procedurecasecc into v_casetypeid, v_procedureid
    from tbl_casecc cs
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
    insert into tbl_cw_workitemcc(col_workflow, col_activity, col_cw_workitemccdict_casest, col_instanceid, col_owner, col_createdby, col_createddate, col_instancetype)
      values(f_UTIL_getDomainFn() || '_' || f_DCM_getCaseWorkflowCodeFn(),
             (select col_activity from tbl_dict_casestate where col_id = v_stateid),
             v_stateid, sys_guid(), sys_context('CLIENTCONTEXT', 'AccessSubject'), sys_context('CLIENTCONTEXT', 'AccessSubject'), sysdate, 1);
    v_ErrorCode := 0;
    v_ErrorMessage := '';
    select gen_tbl_cw_workitemcc.currval into v_workItemid from dual;
    update tbl_casecc
     set col_cw_workitemcccasecc = v_workItemid,
     col_activity = (select col_activity from tbl_dict_casestate where col_id = v_stateid),
     col_workflow = f_UTIL_getDomainFn() || '_' || f_DCM_getCaseWorkflowCodeFn(),
     col_caseccdict_casestate = v_stateid
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
      update tbl_casecc set col_procedurecasecc = v_procedureid where col_id = v_CaseId;
    end if;
  end if;
  :ProcedureId := v_procedureid;
end;