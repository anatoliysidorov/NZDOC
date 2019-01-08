declare
  v_CaseId Integer;
  v_stateNew nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateFixed nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_state nvarchar2(255);
  v_target nvarchar2(255);
  v_transition nvarchar2(255);
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
  v_CaseStateInitId Integer;
  v_CaseStateInitProc nvarchar2(255);
  v_CaseStateInitAssignProc nvarchar2(255);
  v_DebugSession nvarchar2(255);
  v_resolutionAssigned number;
begin
  v_CaseId := :CaseId;
  v_stateNew := f_dcm_getCaseNewState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateAssigned := f_dcm_getCaseAssignedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateInProcess := f_dcm_getCaseInProcessState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateFixed := f_dcm_getCaseFixedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateResolved := f_dcm_getCaseResolvedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateClosed := f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_IsValid := 1;
  v_sysdate := sysdate;
  v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId, CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId), ProcedureId => null);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'DCM_caseRouteAutomaticFn begin', Message => 'Before routing case ' || to_char(v_CaseId), Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
  begin
    select cwi.col_activity into v_state from tbl_case cs inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
      where cs.col_id = v_CaseId;
    exception
      when NO_DATA_FOUND then
        return -1;
  end;
  begin
    select col_activity into v_result2 from tbl_dict_casestate where col_activity = v_state
          and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId));
      exception
        when NO_DATA_FOUND then
          return -1;
  end;
  v_transition := f_DCM_getNextCaseTransAuto2(CaseActivity => v_state, CaseId => v_CaseId);
  if v_transition is null then
    return -1;
  end if;
  v_state := f_DCM_getNextCaseActtyAuto2(CaseActivity => v_state, CaseId => v_CaseId);
  if v_state is null then
    return -1;
  end if;
  begin
    select s1.CaseId, s1.CaseTitle, s1.CaseSysType, s1.CaseDateAssigned, s1.CaseDateClosed, s1.CaseDescription, s1.CaseStateInitId, s1.CaseStateInitProc, s1.CaseStateInitAssignProc,
           s1.CaseWorkitemId, s1.CaseTargetActivity
       into v_CaseId2, v_CaseTitle, v_CaseSysType,
            v_DateAssigned, v_DateClosed, v_Description, v_CaseStateInitId, v_CaseStateInitProc, v_CaseStateInitAssignProc, v_CaseWorkitemId, v_target
    from
    (select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
       cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
       cse.col_description as CaseDescription, mcsi.col_id as CaseStateInitId, mcsi.col_processorcode as CaseStateInitProc, mcsi.col_assignprocessorcode as CaseStateInitAssignProc,
       cwi.col_id as CaseWorkitemId, dcs.col_activity as CaseTargetActivity
                from tbl_case cs
                inner join tbl_caseext cse on cs.col_id = cse.col_caseextcase
                inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
                inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
                inner join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase
                inner join tbl_dict_casestate dcs on mcsi.col_map_csstinit_csst = dcs.col_id
                inner join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
                where cs.col_id = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and cwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and lower(dim.col_code) = 'automatic_config'
                and dcs.col_activity = v_state
                --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY FINISH-TO-START DEPENDENCY TYPE (FS) THAT ARE NOT CLOSED
                --TASK IS CONSIDERED NOT CLOSED IF TASK STATE IS NOT 'root_TSK_Status_CLOSED'
                and cs.col_id not in (select csic.col_map_casestateinitcase
                                         --SELECT FROM TASK DEPENDENCY
                                         from tbl_casedependency cd
                                         --JOIN TASK INITIATION RECORDS FOR CHILD CASE TASK
                                         inner join tbl_map_casestateinitiation csic on cd.col_casedpndchldcasestateinit = csic.col_id
                                         --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                         inner join tbl_map_taskstateinitiation tsip on cd.col_casedpndprnttaskstateinit = tsip.col_id
                                         --JOIN CHILD CASE
                                         inner join tbl_case csc on csic.col_map_casestateinitcase = csc.col_id
                                         --JOIN PARENT TASK
                                         inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                                         --JOIN CHILD WORKITEM
                                         inner join tbl_cw_workitem cwic on csc.col_cw_workitemcase = cwic.col_id
                                         --JOIN PARENT WORKITEM
                                         inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                                         --JOIN CHILD CASE STATE
                                         inner join tbl_dict_casestate dcsc on csic.col_map_csstinit_csst = dcsc.col_id
                                         --JOIN PARENT TASK STATE
                                         inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                                         where csc.col_id = v_CaseId
                                         --FILTER CHILD CASE INITIATION RECORDS TO TARGET STATE
                                         and dcsc.col_activity = v_state
                                         and cwic.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                                         and twip.col_activity <> dtsp.col_activity
                                         --FILTER DEPENDENCY TO TYPE 'FS' ONLY
                                         and cd.col_type = 'FS'
                                      )
    union all
    select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
       cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
       cse.col_description as CaseDescription, mcsi.col_id as CaseStateInitId, mcsi.col_processorcode as CaseStateInitProc, mcsi.col_assignprocessorcode as CaseStateInitAssignProc,
       cwi.col_id as CaseWorkitemId, dcs.col_activity as CaseTargetActivity
              from tbl_case cs
              inner join tbl_caseext cse on cs.col_id = cse.col_caseextcase
              inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
              inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
              inner join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase
              inner join tbl_dict_casestate dcs on mcsi.col_map_csstinit_csst = dcs.col_id
              inner join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
              where cs.col_id = v_CaseId
              --CASES WITH STATUS 'root_CS_Status_NEW' CAN BE ASSIGNED
              and cwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
              and (dcst.col_code is not null)
              and lower(dim.col_code) = 'automatic'
              and dcs.col_activity = v_state
    union all
    select cs.col_id as CaseId, cs.col_caseid as CaseTitle, dcst.col_code as CaseSysType,
                cs.col_dateassigned as CaseDateAssigned, cs.col_dateclosed as CaseDateClosed,
                cse.col_description as CaseDescription, mcsi.col_id as CaseStateInitId, mcsi.col_processorcode as CaseStateInitProc, mcsi.col_assignprocessorcode as CaseStateInitAssignProc,
                cwi.col_id as CaseWorkitemId, dcs.col_activity as CaseTargetActivity
                from tbl_case cs
                inner join tbl_caseext cse on cs.col_id = cse.col_caseextcase
                inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id
                inner join tbl_dict_casesystype dcst on cs.col_casedict_casesystype = dcst.col_id
                inner join tbl_map_casestateinitiation mcsi on cs.col_id = mcsi.col_map_casestateinitcase
                inner join tbl_dict_casestate dcs on mcsi.col_map_csstinit_csst = dcs.col_id
                inner join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
                where cs.col_id = v_CaseId
                --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                and cwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and lower(dim.col_code) = 'automatic_rule'
                and dcs.col_activity = v_state
                and cs.col_id not in
                (select chldcs.col_id
                from tbl_task tsk
                left  join tbl_stp_resolutioncode src on tsk.col_taskstp_resolutioncode = src.col_id
                inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
                inner join tbl_dict_tasksystype dtst on tsk.col_taskdict_tasksystype = dtst.col_id
                inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
                inner join tbl_dict_taskstate dts on mtsi.col_map_tskstinit_tskst = dts.col_id
                inner join tbl_dict_initmethod dim on mtsi.col_map_tskstinit_initmtd = dim.col_id
                inner join tbl_casedependency cd on mtsi.col_id = cd.col_casedpndprnttaskstateinit and cd.col_type in ('FSC', 'FS')
                inner join tbl_map_casestateinitiation chldmcsi on cd.col_casedpndchldcasestateinit = chldmcsi.col_id
                inner join tbl_dict_casestate chlddcs on chldmcsi.col_map_csstinit_csst = chlddcs.col_id
                inner join tbl_case chldcs on chldmcsi.col_map_casestateinitcase = chldcs.col_id
                inner join tbl_cw_workitem chldcwi on chldcs.col_cw_workitemcase = chldcwi.col_id
                inner join tbl_dict_casesystype chlddcst on chldcs.col_casedict_casesystype = chlddcst.col_id
                inner join tbl_dict_initmethod chlddim on chldmcsi.col_casestateinit_initmethod = chlddim.col_id
                left  join tbl_autoruleparameter chldarp on chldmcsi.col_id = chldarp.col_ruleparam_casestateinit
                where chldcs.col_id = v_CaseId
                and chldcwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and chlddcs.col_activity = v_state
                and lower(chlddim.col_code) = 'automatic_rule'
                and (twi.col_activity <> dts.col_activity
                     or (case when cd.col_processorcode is not null then f_DCM_invokeCaseProcessor2(cd.col_id, cd.col_processorcode)
                              when chldmcsi.col_processorcode is not null then f_DCM_invokeCaseProcessor(chldmcsi.col_id, chldmcsi.col_processorcode)
                              else 1 end) <> 1)
                union all
                select chldcs.col_id
                from tbl_casedependency cd
                inner join tbl_map_casestateinitiation chldmcsi on cd.col_casedpndchldcasestateinit = chldmcsi.col_id
                inner join tbl_dict_casestate chlddcs on chldmcsi.col_map_csstinit_csst = chlddcs.col_id
                inner join tbl_case chldcs on chldmcsi.col_map_casestateinitcase = chldcs.col_id
                inner join tbl_cw_workitem chldcwi on chldcs.col_cw_workitemcase = chldcwi.col_id
                inner join tbl_dict_casesystype chlddcst on chldcs.col_casedict_casesystype = chlddcst.col_id
                inner join tbl_dict_initmethod chlddim on chldmcsi.col_casestateinit_initmethod = chlddim.col_id
                inner join tbl_globalevent ge on cd.col_casedependencyglobalevent = ge.col_id
                inner join tbl_listener lsnr on ge.col_id = lsnr.col_listenerglobalevent
                where chldcs.col_id = v_CaseId
                and chldcwi.col_activity = f_DCM_getPrevCaseActivity3(CaseActivity => v_state, CaseId => v_CaseId, Transition => v_transition)
                and chlddcs.col_activity = v_state
                and ((lower(chlddim.col_code) = 'manual_rule') or (lower(chlddim.col_code) = 'automatic_rule'))
                and cd.col_type = 'GC'
                and f_DCM_invokeCaseProcessor2(cd.col_id, lsnr.col_processorcode) <> 1
                )) s1;
    exception
      when NO_DATA_FOUND then
        v_IsValid := 0;
        return -1;
      when TOO_MANY_ROWS then
        v_IsValid := 0;
        return -1;
  end;
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before validation', Message => 'Case ' || to_char(v_CaseId) || ' before validation', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
  v_result := f_DCM_processCaseEvent2(CaseId => v_CaseId, EventState => v_target, EventType => 'before', IsValid => v_IsValid);
  v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'Before validation', Message => 'Case ' || to_char(v_CaseId) || ' after validation with validation result: ' || to_char(v_IsValid),
                                   Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
  if v_IsValid = 1 then
    v_resolutionAssigned := 0;
    begin
      --SET CASE rec.CaseId IN CURSOR rec TO STATE v_target
      update tbl_cw_workitem set col_activity = v_target, col_cw_workitemprevcasestate = col_cw_workitemdict_casestate, col_cw_workitemdict_casestate = (select col_id from tbl_dict_casestate where col_activity = v_target
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))
        where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_CaseId);
      update tbl_case set col_activity = v_target, col_casedict_casestate = (select col_id from tbl_dict_casestate where col_activity = v_target
      and nvl(col_stateconfigcasestate,0) = (select nvl(col_stateconfigcasesystype,0) from tbl_dict_casesystype where col_id =
      (select col_casedict_casesystype from tbl_case where col_id = v_CaseId)))
        where col_id = v_CaseId;
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case routing', Message => 'Case ' || to_char(v_CaseId) || ' after routing to state ' || v_target, Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
      if v_target = v_stateAssigned then
        v_result := f_DCM_invokeCaseAssignProc(ProcessorName => v_CaseStateInitAssignProc, CaseId => v_CaseId);
        v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case routing', Message => 'Case ' || to_char(v_CaseId) || ' after assignment', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
      end if;
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
            update tbl_case set col_dateassigned = null where col_id = v_CaseId;
          elsif rec2.ForcedOverwrite = 1 then
            update tbl_case set col_dateassigned = v_sysdate where col_id = v_CaseId;
          elsif rec2.NullOverwrite = 1 then
            update tbl_case set col_dateassigned = v_sysdate where col_id = v_CaseId and col_dateassigned is null;
          end if;
        elsif rec2.casestatesetupcode = 'DATECLOSED' then
          update tbl_case set col_dateclosed = v_sysdate where col_id = v_CaseId;
        elsif rec2.casestatesetupcode = 'WORKBASKET' then
          if rec2.ForcedNull = 1 then
            update tbl_case set col_caseppl_workbasket = null where col_id = v_CaseId;
          elsif rec2.ForcedOverwrite = 1 then
            update tbl_case set col_caseppl_workbasket = col_caseppl_workbasket where col_id = v_CaseId;
          end if;
        elsif rec2.casestatesetupcode = 'RESOLUTION' then
          update tbl_case set col_stp_resolutioncodecase = col_stp_resolutioncodecase where col_id = v_CaseId;
          v_resolutionAssigned := 1;
        end if;
      end loop;
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case properties set', Message => 'Case ' || to_char(v_CaseId) || ' after case properties DateAssigned, DateClosed, Workbasket, Resolution are set',
                                       Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
      v_result := f_DCM_addCaseDateEventList2(CaseId => v_CaseId);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case date events added', Message => 'Case ' || to_char(v_CaseId) || ' after date events added', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
      exception
        when NO_DATA_FOUND then
          return -1;
    end;
    --CREATE NOTIFICATION
    v_result := f_DCM_createNotification(CaseId => v_CaseId, NotificationTypeCode => 'CASE_MOVED', TaskId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After notification created', Message => 'Case ' || to_char(v_CaseId) || ' notification created', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    --AFTER TRANSITION ACTION SYNCHRONOUS EVENTS
    v_result := f_DCM_processCaseEvent3(CaseId => v_CaseId, EventState => v_state, IsValid => v_IsValid);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After ''After routing'' synchronous events', Message => 'Case ' || to_char(v_CaseId) || ' after ''After routing'' synchronous events',
                                     Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    --INVALIDATE CASE WHERE CASE CHANGED ITS STATE
    if v_resolutionAssigned = 0 then
      v_result := f_DCM_createCaseHistory (MessageCode => 'CaseStateRouted', CaseId => v_CaseId, IsSystem => 1);
    elsif v_resolutionAssigned = 1 then
      v_result := f_DCM_createCaseHistory (MessageCode => 'CaseStateRoutedWithResolution', CaseId => v_CaseId, IsSystem => 1);
    end if;
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After case history created', Message => 'Case ' || to_char(v_CaseId) || ' history created created', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
    --REGISTER AFTER EVENTS FOR CASE v_target STATE
    v_result := f_dcm_regcaseaftereventfn(CaseId => v_CaseId);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After ''After routing'' asynchronous events registered', Message => 'Case ' || to_char(v_CaseId) || ' after ''After routing'' asynchronous events registered',
                                     Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    --v_result := f_dcm_statCaseCalc(CaseId => v_CaseId);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After statistics calculated', Message => 'Case ' || to_char(v_CaseId) || ' after statistics calculated', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    if v_target = f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId)) then
      v_result := f_dcm_statCaseUpdate(CaseId => v_CaseId);
      v_result := f_DBG_createDBGTrace(CaseId => v_CaseId, Location => 'After statistics updated', Message => 'Case ' || to_char(v_CaseId) || ' after statistics updated', Rule => 'DCM_caseRouteAutomaticFn', TaskId => null);
    end if;
  else
    return -1;
  end if;
end;