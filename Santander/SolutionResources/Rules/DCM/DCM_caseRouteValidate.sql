declare
  v_CaseId Integer;
  v_Target nvarchar2(255);
  v_transition nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateFixed nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_stateTaskClosed nvarchar2(255);
  v_state nvarchar2(255);
  v_sysdate date;
  v_InitMethod nvarchar2(255);
  v_result number;
  v_result2 nvarchar2(255);
  v_IsValid number;
begin
  v_CaseId := :CaseId;
  v_Target := :Target;
  v_sysdate := sysdate;
  v_stateNew := f_dcm_getCaseNewState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateAssigned := f_dcm_getCaseAssignedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateInProcess := f_dcm_getCaseInProcessState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateFixed := f_dcm_getCaseFixedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateResolved := f_dcm_getCaseResolvedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateClosed := f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateTaskClosed := f_dcm_getTaskClosedState();
  v_IsValid := 1;
  :ErrorCode := null;
  :ErrorMessage := null;
  begin
    select cwi.col_activity into v_state from tbl_case cs inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
      where cs.col_id = v_CaseId;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 104;
        :ErrorMessage := 'Case not found';
        return -1;
  end;
  begin
    select col_activity into v_result2 from tbl_dict_casestate where col_activity = v_state
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          :ErrorCode := 105;
          :ErrorMessage := 'Case state undefined';
          return -1;
  end;
  v_transition := f_DCM_getCaseTransition3(CaseId => v_CaseId, Source => v_state, Target => v_target);
  if (v_transition = 'NONE') then
    :ErrorCode := 105;
    :ErrorMessage := 'Transition not found';
    return -1;
  end if;
  begin
    select f_dcm_iscasetransitionallow(AccessObjectId => (select Id from table(f_dcm_getCaseTransAOList())
       where CaseTransitionId = (select col_id from tbl_dict_casetransition where lower(col_transition) = lower(v_transition)
                                 and col_sourcecasetranscasestate in 
                                 (select col_id from tbl_dict_casestate where nvl(col_stateconfigcasestate,0) =
                                   (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
                                     (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))
                                  and col_targetcasetranscasestate in 
                                 (select col_id from tbl_dict_casestate where nvl(col_stateconfigcasestate,0) =
                                   (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
                                     (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))))) into v_result from dual;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
  end;
  if v_result = 0 then
    :ErrorCode := 112;
    :ErrorMessage := 'Routing by transition ' || v_transition || ' is not allowed by your security settings';
    return -1;
  end if;
  if (f_DCM_getNextCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition) <> v_target) then
    :ErrorCode := 111;
    :ErrorMessage := 'Case cannot be sent from state ' || v_state || ' to state ' || v_target;
    return -1;
  end if;
  begin
    select f_DCM_getNextCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition) into v_state from dual;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 106;
        :ErrorMessage := 'Case next state undefined';
        return -1;
  end;
  begin
    select col_activity into v_result2 from tbl_dict_casestate where col_activity = v_state
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
         :ErrorCode := 107;
         :ErrorMessage := 'Case next state undefined';
         return -1;
  end;
  begin
    select dim.col_code into v_InitMethod
      from tbl_case cs
      inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
      inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
      inner join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase
      inner join tbl_dict_casestate dcs on mcsi.col_map_csstinit_csst = dcs.col_id
      inner join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
      where cs.col_id = v_CaseId
      and cwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
      and dcs.col_activity = v_state;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 108;
        :ErrorMessage := 'Case ' || v_CaseId || ' state ' || v_state || ' not found';
        return -1;
  end;
  begin
    select count(*) into v_result
      from tbl_task tsk
      inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      where tsk.col_casetask = v_CaseId
      and target = v_stateClosed
      and twi.col_activity <> v_stateTaskClosed
      and tsk.col_required = 1;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 109;
        :ErrorMessage := 'Tasks for Case ' || v_CaseId || ' not found';
        return -1;
  end;
  if v_result > 0 then
    :ErrorCode := 110;
    :ErrorMessage := 'Case ' || v_CaseId || ' cannot be closed because not all required tasks are closed ';
    return -1;
  end if;

end;