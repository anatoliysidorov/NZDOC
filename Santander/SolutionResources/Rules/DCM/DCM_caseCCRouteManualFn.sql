declare
  v_CaseId Integer;
  v_WorkbasketId Integer;
  v_ResolutionId Integer;
  v_stateNew nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateFixed nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_state nvarchar2(255);
  v_transition nvarchar2(255);
  v_target nvarchar2(255);
  v_result number;
  v_result2 nvarchar2(255);
  v_IsValid number;
  v_CaseId2 Integer;
  v_CaseTitle nvarchar2(255);
  v_CaseSysType nvarchar2(255);
  v_DateAssigned date;
  v_DateClosed date;
  v_Description nclob;
  v_CaseWorkitemId Integer;
  v_DateEventName nvarchar2(255);
  v_sysdate date;
  v_DebugSession nvarchar2(255);
  v_resolutionAssigned number;
begin
  v_CaseId := :CaseId;
  v_target := :Target;
  v_WorkbasketId := :WorkbasketId;
  v_ResolutionId := :ResolutionId;
  v_stateNew := f_dcm_getCaseNewState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateAssigned := f_dcm_getCaseAssignedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateInProcess := f_dcm_getCaseInProcessState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateFixed := f_dcm_getCaseFixedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateResolved := f_dcm_getCaseResolvedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateClosed := f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_IsValid := 1;
  v_sysdate := sysdate;
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_caseRouteManualFn begin', Message => 'Before routing case ' || to_char(v_CaseId), Rule => 'DCM_caseRouteManualFn', TaskId => null);
  begin
    select cwi.col_activity into v_state from tbl_casecc cs inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
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
      (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          :ErrorCode := 105;
          :ErrorMessage := 'Case state undefined';
          return -1;
  end;
  v_transition := f_DCM_getCaseCCTransition(CaseId => v_CaseId, Source => v_state, Target => v_target);
  if (v_transition = 'NONE') then
    :ErrorCode := 105;
    :ErrorMessage := 'Transition not found';
    return -1;
  end if;
  begin
    select f_DCM_getNextCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition) into v_state from dual;
    exception
      when NO_DATA_FOUND then
        :ErrorCode := 106;
        :ErrorMessage := 'Task next state undefined';
        return -1;
  end;
  begin
    select col_activity into v_result2 from tbl_dict_casestate where col_activity = v_state
            and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
         :ErrorCode := 107;
         :ErrorMessage := 'Case next state undefined';
         return -1;
  end;
  begin
    select s1.CaseId, s1.CaseTitle, s1.CaseSysType, s1.CaseDateAssigned, s1.CaseDateClosed, s1.CaseDescription, s1.CaseWorkitemId
       into v_CaseId2, v_CaseTitle, v_CaseSysType,
            v_DateAssigned, v_DateClosed, v_Description, v_CaseWorkitemId
    from
    (select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
       cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
       cast(substr(cs.col_description,1,2000) as nvarchar2(2000)) as CaseDescription, cwi.col_id as CaseWorkitemId
                from tbl_casecc cs
                inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
                inner join tbl_dict_casesystype dcst on cs.col_caseccdict_casesystype = dcst.col_id
                inner join tbl_map_casestateinitcc mcsi on cs.col_id = mcsi.col_map_casestateinitcccasecc
                inner join tbl_dict_casestate dcs on mcsi.col_map_csstinitcc_csst = dcs.col_id
                inner join tbl_dict_initmethod dim on mcsi.col_casestateinitcc_initmtd = dim.col_id
                where cs.col_id = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and cwi.col_activity = f_DCM_getPrevCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and ((lower(dim.col_code) = 'manual_config') or (lower(dim.col_code) = 'automatic_config'))
                and dcs.col_activity = v_state
                --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY FINISH-TO-START DEPENDENCY TYPE (FS) THAT ARE NOT CLOSED
                --TASK IS CONSIDERED NOT CLOSED IF TASK STATE IS NOT 'root_TSK_Status_CLOSED'
                and cs.col_id not in (select csic.col_map_casestateinitcccasecc
                                         --SELECT FROM TASK DEPENDENCY
                                         from tbl_casedependencycc cd
                                         --JOIN TASK INITIATION RECORDS FOR CHILD CASE TASK
                                         inner join tbl_map_casestateinitcc csic on cd.col_casedpchldcccasestinitcc = csic.col_id
                                         --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                         inner join tbl_map_taskstateinitcc tsip on cd.col_casedpprntcctaskstinitcc = tsip.col_id
                                         --JOIN CHILD CASE
                                         inner join tbl_casecc csc on csic.col_map_casestateinitcccasecc = csc.col_id
                                         --JOIN PARENT TASK
                                         inner join tbl_taskcc tskp on tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                                         --JOIN CHILD WORKITEM
                                         inner join tbl_cw_workitemcc cwic on csc.col_cw_workitemcccasecc = cwic.col_id
                                         --JOIN PARENT WORKITEM
                                         inner join tbl_tw_workitemcc twip on tskp.col_tw_workitemcctaskcc = twip.col_id
                                         --JOIN CHILD CASE STATE
                                         inner join tbl_dict_casestate dcsc on csic.col_map_csstinitcc_csst = dcsc.col_id
                                         --JOIN PARENT TASK STATE
                                         inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinitcc_tskst = dtsp.col_id
                                         where csc.col_id = v_CaseId
                                         --FILTER CHILD CASE INITIATION RECORDS TO TARGET STATE
                                         and dcsc.col_activity = v_state
                                         and cwic.col_activity = f_DCM_getPrevCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                                         and twip.col_activity <> dtsp.col_activity
                                         --FILTER DEPENDENCY TO TYPE 'FS' ONLY
                                         and cd.col_type = 'FS'
                                      )
    union
    select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
       cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
       cast(substr(cs.col_description,1,2000) as nvarchar2(2000)) as CaseDescription,
       cwi.col_id as CaseWorkitemId
              from tbl_casecc cs
              inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
              inner join tbl_dict_casesystype dcst on cs.col_caseccdict_casesystype = dcst.col_id
              inner join tbl_map_casestateinitcc mcsi on cs.col_id = mcsi.col_map_casestateinitcccasecc
              inner join tbl_dict_casestate dcs on mcsi.col_map_csstinitcc_csst = dcs.col_id
              inner join tbl_dict_initmethod dim on mcsi.col_casestateinitcc_initmtd = dim.col_id
              where cs.col_id = v_CaseId
              --CASES WITH STATUS 'root_CS_Status_NEW' CAN BE ASSIGNED
              and cwi.col_activity = f_DCM_getPrevCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
              and (dcst.col_code is not null)
              and ((lower(dim.col_code) = 'manual') or (lower(dim.col_code) = 'automatic'))
              and dcs.col_activity = v_state
    union
    select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
                          cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
                          cast(substr(cs.col_description,1,2000) as nvarchar2(2000)) as CaseDescription, cwi.col_id as CaseWorkitemId
                from tbl_casecc cs
                inner join tbl_cw_workitemcc cwi on cs.col_cw_workitemcccasecc = cwi.col_id
                inner join tbl_dict_casesystype dcst on cs.col_caseccdict_casesystype = dcst.col_id
                inner join tbl_map_casestateinitcc mcsi on cs.col_id = mcsi.col_map_casestateinitcccasecc
                inner join tbl_dict_casestate dcs on mcsi.col_map_csstinitcc_csst = dcs.col_id
                inner join tbl_dict_initmethod dim on mcsi.col_casestateinitcc_initmtd = dim.col_id
                where cs.col_id = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and cwi.col_activity = f_DCM_getPrevCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and ((lower(dim.col_code) = 'manual_rule') or (lower(dim.col_code) = 'automatic_rule'))
                and dcs.col_activity = v_state
                and cs.col_id not in
                (select chldcs.col_id
                from tbl_taskcc tsk
                left  join tbl_stp_resolutioncode src on tsk.col_taskccstp_resolutioncode = src.col_id
                inner join tbl_tw_workitemcc twi on tsk.col_tw_workitemcctaskcc = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskccdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitcc mtsi on tsk.col_id = mtsi.col_map_taskstateinitcctaskcc
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinitcc_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinitcc_initmtd = dim.col_id
                inner join tbl_casedependencycc cd on mtsi.col_id = cd.col_casedpprntcctaskstinitcc and cd.col_type in ('FSC', 'FS')
                inner join tbl_map_casestateinitcc chldmcsi on cd.col_casedpchldcccasestinitcc = chldmcsi.col_id
                inner join tbl_dict_casestate chlddcs on chldmcsi.col_map_csstinitcc_csst = chlddcs.col_id
                inner join tbl_casecc chldcs on chldmcsi.col_map_casestateinitcccasecc = chldcs.col_id
                inner join tbl_cw_workitemcc chldcwi on chldcs.col_cw_workitemcccasecc = chldcwi.col_id
                inner join tbl_dict_casesystype chlddcst on chldcs.col_caseccdict_casesystype = chlddcst.col_id
                inner join tbl_dict_initmethod chlddim on chldmcsi.col_casestateinitcc_initmtd = chlddim.col_id
                left  join tbl_autoruleparamcc chldarp on chldmcsi.col_id = chldarp.col_ruleparcc_casestateinitcc
                where chldcs.col_id = v_CaseId
                and chldcwi.col_activity = f_DCM_getPrevCaseCCActivity(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and chlddcs.col_activity = v_state
                and ((lower(chlddim.col_code) = 'manual_rule') or (lower(chlddim.col_code) = 'automatic_rule'))
                and (twi.col_activity <> dts.col_activity
                     or (case when cd.col_processorcode is not null then f_DCM_invokeCaseProcessor2(cd.col_id, cd.col_processorcode)
                              when chldmcsi.col_processorcode is not null then f_DCM_invokeCaseProcessor(chldmcsi.col_id, chldmcsi.col_processorcode)
                              else 1 end) <> 1)
                )) s1;
    exception
      when NO_DATA_FOUND then
        v_IsValid := 0;
        :ErrorCode := 103;
        :ErrorMessage := 'Case cannot be moved';
        return -1;
  end;
  --BEFORE ROUTING VALIDATION EVENTS
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before processing of before routing validation events',
                                   Message => 'Case ' || to_char(v_CaseId) || ' before processing of before routing to ' || v_state || ' validation events', Rule => 'DCM_caseRouteManualFn', TaskId => null);
  v_result := f_DCM_processCaseEvent2(CaseId => v_CaseId, EventState => v_state, EventType => 'before', IsValid => v_IsValid);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After processing of before routing validation events',
                                   Message => 'Case ' || to_char(v_CaseId) || ' after processing of before routing to ' || v_state || ' validation events', Rule => 'DCM_caseRouteManualFn', TaskId => null);
  if v_IsValid = 1 then
    v_resolutionAssigned := 0;
    begin
      --SET CASE rec.CaseId IN CURSOR rec TO STATE v_state
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before case ' || to_char(v_CaseId) || ' routing',
                                       Message => 'Case ' || to_char(v_CaseId) || ' before being routed to activity ' || v_state, Rule => 'DCM_caseRouteManualFn', TaskId => null);
      update tbl_cw_workitemcc set col_activity = v_state, col_cw_workitemccprevcasest = col_cw_workitemccdict_casest, col_cw_workitemccdict_casest = (select col_id from tbl_dict_casestate where col_activity = v_state
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId)))
        where col_id = (select col_cw_workitemcccasecc from tbl_casecc where col_id = v_CaseId);
      update tbl_casecc set col_activity = v_state, col_caseccdict_casestate = (select col_id from tbl_dict_casestate where col_activity = v_state
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_caseccdict_casesystype from tbl_casecc where col_id = v_CaseId)))
        where col_id = v_CaseId;
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case ' || to_char(v_CaseId) || ' routing',
                                       Message => 'Case ' || to_char(v_CaseId) || ' after being routed to activity ' || v_state, Rule => 'DCM_caseRouteManualFn', TaskId => null);
      for rec2 in
      (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
              cst.col_id as CaseStateSetupId, cst.col_name as CaseStateSetupName, cst.col_code as CaseStateSetupCode,
              cst.col_forcednull as ForcedNull, cst.col_forcedoverwrite as ForcedOverwrite, cst.col_notnulloverwrite as NotNullOverwrite, cst.col_nulloverwrite as NullOverwrite
       from tbl_dict_casestate cs
       inner join tbl_dict_casestatesetup cst on cs.col_id = cst.col_casestatesetupcasestate
       where cs.col_activity = v_state)
      loop
        if rec2.casestatesetupcode = 'DATEASSIGNED' then
          if rec2.ForcedNull = 1 then
            update tbl_casecc set col_dateassigned = null where col_id = v_CaseId;
          elsif rec2.ForcedOverwrite = 1 then
            update tbl_casecc set col_dateassigned = v_sysdate where col_id = v_CaseId;
          end if;
        elsif rec2.casestatesetupcode = 'DATECLOSED' then
          update tbl_casecc set col_dateclosed = v_sysdate where col_id = v_CaseId;
        elsif rec2.casestatesetupcode = 'WORKBASKET' then
          if rec2.ForcedNull = 1 then
            update tbl_casecc set col_caseccppl_workbasket = null where col_id = v_CaseId;
          elsif rec2.ForcedOverwrite = 1 then
            update tbl_casecc set col_caseccppl_workbasket = v_WorkbasketId where col_id = v_CaseId;
          end if;
        elsif rec2.casestatesetupcode = 'RESOLUTION' then
          update tbl_casecc set col_stp_resolutioncodecasecc = v_ResolutionId where col_id = v_CaseId;
          v_resolutionAssigned := 1;
        end if;
      end loop;
      v_result := f_DCM_addCaseDateEventCCList(CaseId => v_CaseId);
      exception
        when NO_DATA_FOUND then
          :ErrorCode := 101;
          :ErrorMessage := 'Case transition failed';
          return -1;
    end;
    --CREATE NOTIFICATION
    v_result := f_DCM_createNotification(CaseId => v_CaseId, NotificationTypeCode => 'CASE_MOVED', TaskId => null);
    --INVALIDATE CASE WHERE CASE CHANGED ITS STATE
    if v_resolutionAssigned = 0 then
      v_result := f_DCM_createCaseHistoryCC (MessageCode => 'CaseStateRouted', CaseId => v_CaseId, IsSystem => 0);
    elsif v_resolutionAssigned = 1 then
      v_result := f_DCM_createCaseHistoryCC (MessageCode => 'CaseStateRoutedWithResolution', CaseId => v_CaseId, IsSystem => 0);
    end if;
    v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before call to dcm_casequeueproc5',
                                     Message => 'Before call to dcm_casequeueproc5', Rule => 'DCM_caseRouteManualFn', TaskId => null);
    v_result := f_dcm_casequeueproc7();
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After call to dcm_casequeueproc5',
                                     Message => 'After call to dcm_casequeueproc5', Rule => 'DCM_caseRouteManualFn', TaskId => null);
    --REGISTER AFTER EVENTS FOR CASE v_state STATE
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before processing of --after task routing action-- asynchronous events',
                                     Message => 'Case ' || to_char(v_CaseId) || ' before processing of --after task routing action-- asynchronous events' || v_state, Rule => 'DCM_caseRouteManualFn', TaskId => null);
    v_result := f_dcm_regcaseaftereventfn(CaseId => v_CaseId);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After processing of --after task routing action-- asynchronous events',
                                     Message => 'Case ' || to_char(v_CaseId) || ' after processing of --after task routing action-- asynchronous events' || v_state, Rule => 'DCM_caseRouteManualFn', TaskId => null);
    --v_result := f_dcm_statCaseCalc(CaseId => v_CaseId);
    if v_state = f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId)) then
      v_result := f_dcm_statCaseUpdate(CaseId => v_CaseId);
    end if;
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_caseRouteManualFn end',
                                     Message => 'After case ' || to_char(v_CaseId) || ' routing succeeded', Rule => 'DCM_caseRouteManualFn', TaskId => null);
  else
    :ErrorCode := 102;
    :ErrorMessage := 'Case transition validation failed';
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_caseRouteManualFn end',
                                     Message => 'After case ' || to_char(v_CaseId) || ' routing failed', Rule => 'DCM_caseRouteManualFn', TaskId => null);
    return -1;
  end if;
end;