--RULE FINDS ALL RELATED TO CASE TASKS THAT ARE ELIGIBLE FOR STARTING AND STARTS THEM
declare
    v_CaseId Integer;
    v_stateNew nvarchar2(255);
    v_stateStarted nvarchar2(255);
    v_stateAssigned nvarchar2(255);
    v_stateInProcess nvarchar2(255);
    v_stateResolved nvarchar2(255);
    v_stateClosed nvarchar2(255);
    v_stateCode nvarchar2(255);
    v_state nvarchar2(255);
    v_sysdate date;
    v_IsValid number;
    v_result number;
    v_Message nclob;
    v_CaseInvalid number;
    v_DebugSession nvarchar2(255);
begin
    v_CaseId := :CaseId;
    v_sysdate := sysdate;
    v_stateNew := f_dcm_getTaskNewState();
    v_stateStarted := f_dcm_getTaskStartedState();
    v_stateAssigned := f_dcm_getTaskAssignedState();
    v_stateInProcess := f_dcm_getTaskInProcessState();
    v_stateResolved := f_dcm_getTaskResolvedState();
    v_stateClosed := f_dcm_getTaskClosedState();
    v_IsValid := 1;
    v_CaseInvalid := 0;
    v_DebugSession := f_DBG_createDBGSession(CaseId => v_CaseId,
                                             CaseTypeId => f_dcm_getcasetypeforcase(CaseId => v_CaseId),
                                             ProcedureId => null);
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                     Location => 'DCM_routeCaseTasksFn3 begin',
                                     Message => 'Before routing tasks in case ' || to_char(v_CaseId),
                                     Rule => 'DCM_routeCaseTasksFn3',
                                     TaskId => null);
    --SELECT ALL TASKS ELIGIBLE FOR TRANSITION FROM 'NEW' TO 'STARTED' STATE
    --RESULT INCLUDES RECORDS OF FOLLOWING TYPES THAT SATISFY RELATED CONFIGURATION
    --1. INITIATION TYPE 'AUTOMATIC_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
    --2. RECORDS WITH INITIATION TYPE 'AUTOMATIC'
    --3. RECORDS WITH INITIATION TYPE 'AUTOMATIC_RULE'
    for rec in(
    --FIRST FIND RECORDS WITH INITIATION TYPE 'AUTOMATIC_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
    select     tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on dtt.col_sourcetasktranstaskstate = twi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = dts.col_id and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_config'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY FINISH-TO-START DEPENDENCY TYPE (FS) THAT ARE NOT CLOSED
               --TASK IS CONSIDERED NOT CLOSED IF TASK STATE IS NOT 'root_TSK_Status_CLOSED'
               and tsk.col_id not in(select    tsic.col_map_taskstateinittask
                          --SELECT FROM TASK DEPENDENCY
               from       tbl_taskdependency td
                          --JOIN TASK INITIATION RECORDS FOR PARENT TASK
               inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                          --JOIN TASK INITIATION RECORDS FOR CHILD TASK
               inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                          --JOIN PARENT TASK
               inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                          --JOIN CHILD TASK
               inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                          --JOIN PARENT WORKITEM
               inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                          --JOIN CHILD WORKITEM
               inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                          --JOIN PARENT TASK STATE
               inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                          --JOIN CHILD TASK STATE
               inner join tbl_dict_taskstate dtsc      on tsic.col_map_tskstinit_tskst = dtsc.col_id
               inner join tbl_dict_tasktransition dttc on dttc.col_sourcetasktranstaskstate = twic.col_tw_workitemdict_taskstate and dttc.col_targettasktranstaskstate = dtsc.col_id and nvl(dttc.col_manualonly,0) = 0
               where      tskp.col_casetask = v_CaseId
                          --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                          and dtsc.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                          --FILTER OUT PARENT TASKS TO THOSE NOT IN STATE 'root_TSK_Status_CLOSED'
                          and(twip.col_activity <> dtsp.col_activity
                          and tsip.col_routedby is null
                          and tsip.col_routeddate is null)
                          --FILTER DEPENDENCY TO TYPE 'FS' ONLY
                          and td.col_type = 'FS')
               --CHECK THAT TASKS IN SELECT RESULT ITEMS ARE VALID ACCORDING TO "FSO" DEPENDENCY TYPE
               --"FSO" DEPENDENY IS FINISH-TO-START FLAVOR WITH AT LEAST ONE OF PARENT TASKS IS CLOSED
               --THIS MEANS THAT EITHER THOSE TASKS ARE NOT DEPENDENT FROM ANY OTHER TASKS (PARENT TASKS) BY "FSO" DEPENDENCY TYPE
               --OR IF THEY HAVE SUCH DEPENDENCY, AT LEAST ONE PARENT TASK IS IN 'root_TSK_Status_CLOSED' STATE
               and((select count(*)
               from   (select    tsic.col_map_taskstateinittask,
                                  tskc.col_id as TaskId
                       from       tbl_taskdependency td
                                  --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                       inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                                  --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                       inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                                  --JOIN PARENT TASK
                       inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                                  --JOIN CHILD TASK
                       inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                                  --JOIN PARENT WORKITEM
                       inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                                  --JOIN CHILD WORKITEM
                       inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                                  --JOIN PARENT TASK STATE
                       inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                                  --JOIN CHILD TASK STATE
                       inner join tbl_dict_taskstate dtsc on tsic.col_map_tskstinit_tskst = dtsc.col_id
                       where      tskp.col_casetask = v_CaseId
                                  --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                  and dtsc.col_activity in(select null
                                  from    dual
                                  union
                                  select NextActivity
                                  from   table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                                  --FILTER PARENT TASK INITIATION RECORDS TO STATE 'root_TSK_Status_CLOSED'
                                  and twip.col_activity <> dtsp.col_activity
                                  --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                                  and td.col_type = 'FSO') s1
               where   s1.TaskId = tsk.col_id) = 0
               or(select count(*)
               from   (select    tsic.col_map_taskstateinittask,
                                  tskc.col_id as TaskId
                       from       tbl_taskdependency td
                                  --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                       inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                                  --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                       inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                                  --JOIN PARENT TASK
                       inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                                  --JOIN CHILD TASK
                       inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                                  --JOIN PARENT WORKITEM
                       inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                                  --JOIN CHILD WORKITEM
                       inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                                  --JOIN PARENT TASK STATE
                       inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                                  --JOIN CHILD TASK STATE
                       inner join tbl_dict_taskstate dtsc on tsic.col_map_tskstinit_tskst = dtsc.col_id
                       where      tskp.col_casetask = v_CaseId
                                  --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                  and dtsc.col_activity in(select null
                                  from    dual
                                  union
                                  select NextActivity
                                  from   table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                                  --FILTER OUT PARENT TASKS TO THOSE NOT IN STATE 'root_TSK_Status_CLOSED'
                                  and twip.col_activity = dtsp.col_activity
                                  --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                                  and td.col_type = 'FSO') s2
               where   s2.TaskId = tsk.col_id) > 0)
               --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY START-TO-START DEPENDENCY TYPE (SS) THAT ARE NOT STARTED
               --TASK IS CONSIDERED NOT STARTED IF EITHER TASK STATE IS 'root_TSK_Status_NEW' OR TASK DATE ASSIGNED IS NULL
               and tsk.col_id not in(select    tsic.col_map_taskstateinittask
                          --SELECT FROM TASK DEPENDENCY
               from       tbl_taskdependency td
                          --JOIN TASK INITIATION RECORDS FOR PARENT TASK
               inner join tbl_map_taskstateinitiation tsip on td.col_tskdpndprnttskstateinit = tsip.col_id
                          --JOIN TASK INITIATION RECORDS FOR CHILD TASK
               inner join tbl_map_taskstateinitiation tsic on td.col_tskdpndchldtskstateinit = tsic.col_id
                          --JOIN PARENT TASK
               inner join tbl_task tskp on tsip.col_map_taskstateinittask = tskp.col_id
                          --JOIN CHILD TASK
               inner join tbl_task tskc on tsic.col_map_taskstateinittask = tskc.col_id
                          --JOIN PARENT WORKITEM
               inner join tbl_tw_workitem twip on tskp.col_tw_workitemtask = twip.col_id
                          --JOIN CHILD WORKITEM
               inner join tbl_tw_workitem twic on tskc.col_tw_workitemtask = twic.col_id
                          --JOIN PARENT TASK STATE
               inner join tbl_dict_taskstate dtsp on tsip.col_map_tskstinit_tskst = dtsp.col_id
                          --JOIN CHILD TASK STATE
               inner join tbl_dict_taskstate dtsc on tsic.col_map_tskstinit_tskst = dtsc.col_id
               where      tskp.col_casetask = v_CaseId
                          --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                          and dtsc.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => tskc.col_id)))
                          --FILTER PARENT TASKS TO THOSE IN STATE 'root_TSK_Status_NEW'
                          and(twip.col_activity not in(select nexttaskactivity
                          from    table(f_DCM_getNextTaskStates(StartState => dtsp.col_activity)))
                          and twip.col_activity <> dtsp.col_activity)
                          --FILTER DEPENDENCY TO TYPE 'SS' ONLY
                          and td.col_type = 'SS')
    union
    --ADD RECORDS WITH INITIATION TYPE 'AUTOMATIC'
    select     tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on dtt.col_sourcetasktranstaskstate = twi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = dts.col_id and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and lower(dim.col_code) = 'automatic'
    union
    --ADD RECORDS WITH INITIATION TYPE 'AUTOMATIC_RULE'
    --PROCESS DEPENDENCY TYPE 'FSC'
    select     tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and(not exists(select col_tskdpndchldtskstateinit
               from    tbl_taskdependency
               where   col_tskdpndchldtskstateinit = mtsi.col_id)
               or exists(select col_tskdpndchldtskstateinit
               from    tbl_taskdependency
               where   col_tskdpndchldtskstateinit = mtsi.col_id
                       and col_type in('FSC',
                                       'FS')))
               and(tsk.col_id,mtsi.col_id) not in(select    chldtsk.col_id as ChildTaskId,
                          chldmtsi.col_id as ChildMtsiId
               from      (select col_id,
                                  col_taskstp_resolutioncode,
                                  col_tw_workitemtask,
                                  col_taskdict_tasksystype,
                                  col_casetask
                          from    tbl_task
                          where   col_casetask = v_CaseId) tsk
               left join  tbl_stp_resolutioncode src       on tsk.col_taskstp_resolutioncode = src.col_id
               inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
               inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
               inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
               inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
               inner join tbl_taskdependency td            on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSC',
                                                                                                                              'FS',
                                                                                                                              'FSCLR')
               inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
               inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
               inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
               inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
               inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
               inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
               inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
               where      tsk.col_casetask = v_CaseId
                          and chldtwi.col_activity in(select col_activity
                          from    tbl_dict_taskstate)
                          and chlddts.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                          and lower(chlddim.col_code) = 'automatic_rule'
                          and((twi.col_activity <> dts.col_activity)
                          or(case
                                     when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                     when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                          end) <> 1)
               union
               select     chldtsk.col_id as ChildTaskId,
                          chldmtsi.col_id as ChildMtsiId
               from      (select col_id,
                                  col_taskstp_resolutioncode,
                                  col_tw_workitemtask,
                                  col_taskdict_tasksystype,
                                  col_casetask
                          from    tbl_task
                          where   col_casetask = v_CaseId) tsk
               left join  tbl_stp_resolutioncode src       on tsk.col_taskstp_resolutioncode = src.col_id
               inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
               inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
               inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
               inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
               inner join tbl_taskdependency td            on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type not in('FSC',
                                                                                                                                  'FS',
                                                                                                                                  'FSCLR')
               inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
               inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
               inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
               inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
               inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
               inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
               inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
               where      tsk.col_casetask = v_CaseId
                          and chldtwi.col_activity in(select col_activity
                          from    tbl_dict_taskstate)
                          and chlddts.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                          and lower(chlddim.col_code) = 'automatic_rule'
               union
               select     chldtsk.col_id as ChildTaskId,
                          chldmtsi.col_id as ChildMtsiId
               from      (select col_id,
                                  col_taskstp_resolutioncode,
                                  col_tw_workitemtask,
                                  col_taskdict_tasksystype,
                                  col_casetask
                          from    tbl_task
                          where   col_casetask = v_CaseId) tsk
               left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
               inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
               inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
               inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
               inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
               inner join tbl_map_taskstateinitiation chldmtsi on mtsi.col_map_taskstateinittask = chldmtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
               inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
               inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
               inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
               inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
               inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
               where      tsk.col_casetask = v_CaseId
                          and chldtwi.col_activity in(select col_activity
                          from    tbl_dict_taskstate)
                          and chlddts.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                          and chldtsk.col_id = tsk.col_id
                          and chlddts.col_activity = dts.col_activity
                          and lower(chlddim.col_code) = 'automatic_rule'
                          and((twi.col_activity <> dts.col_activity)
                          and(case
                                     when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                          end) <> 1))
    union
    select     tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and(tsk.col_id,mtsi.col_id) in(select s1.ChildTaskId,
                       s1.ChildMTSIId
               from   (select    chldtsk.col_id as ChildTaskId,
                                  tsk.col_id as ParentTaskId,
                                  td.col_id as TaskDependencyId,
                                  chlddts.col_activity as ChildTaskTargetActivity,
                                  mtsi.col_id as MTSIId,
                                  mtsi.col_routeddate as ParentTaskRouteddate,
                                  chldmtsi.col_id as ChildMTSIId,
                                  row_number() over(/*partition by mtsi.col_routeddate*/ order by mtsi.col_routeddate desc) as RowNumber
                       from      (select col_id,
                                          col_taskstp_resolutioncode,
                                          col_tw_workitemtask,
                                          col_taskdict_tasksystype,
                                          col_casetask
                                  from    tbl_task
                                  where   col_casetask = v_CaseId) tsk
                       left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                       inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                       inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                       inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                       inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                       inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                       inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCLR')
                       inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                       inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                       inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                       inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                       inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                       inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                       inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                                  --left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                       where      tsk.col_casetask = v_CaseId
                                  and mtsi.col_routeddate is not null
                                  and chldtwi.col_activity in(select col_activity
                                  from    tbl_dict_taskstate)
                                  and chlddts.col_activity in(select null
                                  from    dual
                                  union
                                  select NextActivity
                                  from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                  and lower(chlddim.col_code) = 'automatic_rule'
                                  and((twi.col_activity = dts.col_activity
                                  or mtsi.col_routedby is null
                                  or mtsi.col_routeddate is null)
                     /*and (case when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode, td.col_id)
                              when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id)
                              else 1 end) = 1*/
                                  and(1 in(select 1
                                  from    dual
                                  where   td.col_processorcode is null
                                          and chldmtsi.col_processorcode is null
                                  union
                                  select f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                  from   dual
                                  where  td.col_processorcode is not null
                                  union
                                  select f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id)
                                  from   dual
                                  where  chldmtsi.col_processorcode is not null
                                         and td.col_processorcode is null)))) s1
               where   s1.RowNumber = 1)
    order by   TaskId)
    --START TASKS ELIGIBLE FOR STARTING--
    --SET TASK STATE AND DATE TASK IS ASSIGNED--
    loop
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    for rec in(select    tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and exists(select col_tskdpndchldtskstateinit
               from    tbl_taskdependency
               where   col_tskdpndchldtskstateinit = mtsi.col_id
                       and col_type = 'FSCA')
               and(tsk.col_id,mtsi.col_id) not in(select    chldtsk.col_id as ChildTaskId,
                          chldmtsi.col_id as ChildMtsiId
               from      (select col_id,
                                  col_taskstp_resolutioncode,
                                  col_tw_workitemtask,
                                  col_taskdict_tasksystype,
                                  col_casetask
                          from    tbl_task
                          where   col_casetask = v_CaseId) tsk
               left join  tbl_stp_resolutioncode src       on tsk.col_taskstp_resolutioncode = src.col_id
               inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
               inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
               inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
               inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
               inner join tbl_taskdependency td            on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FS',
                                                                                                                              'FSC',
                                                                                                                              'FSCLR',
                                                                                                                              'FSCA',
                                                                                                                              'FSCO',
                                                                                                                              'FSCEX')
               inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
               inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
               inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
               inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
               inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
               inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
               inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
               where      tsk.col_casetask = v_CaseId
                          and chldtwi.col_activity in(select col_activity
                          from    tbl_dict_taskstate)
                          and chlddts.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                          and lower(chlddim.col_code) = 'automatic_rule'
                          and((twi.col_activity <> dts.col_activity)
                          or((case
                                     when td.col_processorcode is not null and twi.col_activity = dts.col_activity and mtsi.col_routedby is not null and mtsi.col_routeddate is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                     when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity and mtsi.col_routedby is not null and mtsi.col_routeddate is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id)
                                     when twi.col_activity <> dts.col_activity and mtsi.col_routedby is null and mtsi.col_routeddate is null then 0
                          end) <> 1))
                          and(chldtsk.col_id,chldmtsi.col_id) not in(select    chldtsk.col_id as ChildTaskId,
                                     chldmtsi.col_id as ChildMtsiId
                          from      (select col_id,
                                             col_taskstp_resolutioncode,
                                             col_tw_workitemtask,
                                             col_taskdict_tasksystype,
                                             col_casetask
                                     from    tbl_task
                                     where   col_casetask = v_CaseId) tsk
                          left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                          inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                          inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                          inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                          inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                          inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                          inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCA')
                          inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                          inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                          inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                          inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                          inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                          inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                          inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                          where      tsk.col_casetask = v_CaseId
                                     and chldtwi.col_activity in(select col_activity
                                     from    tbl_dict_taskstate)
                                     and chlddts.col_activity in(select null
                                     from    dual
                                     union
                                     select NextActivity
                                     from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                     and lower(chlddim.col_code) = 'automatic_rule'
                                     and((twi.col_activity = dts.col_activity /*or mtsi.col_routedby is not null*/)
                                     and(case
                                                when td.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                                when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                                     end) = 1)
                                     and f_DCM_validateANDRoutingCond(TaskId => chldtsk.col_id) = 1)))
    loop
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    for rec in(select    tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and exists(select col_tskdpndchldtskstateinit
               from    tbl_taskdependency
               where   col_tskdpndchldtskstateinit = mtsi.col_id
                       and col_type = 'FSCO')
               and(tsk.col_id,mtsi.col_id) not in(select    chldtsk.col_id as ChildsTaskId,
                          chldmtsi.col_id as ChildMtsiId
               from      (select col_id,
                                  col_taskstp_resolutioncode,
                                  col_tw_workitemtask,
                                  col_taskdict_tasksystype,
                                  col_casetask
                          from    tbl_task
                          where   col_casetask = v_CaseId) tsk
               left join  tbl_stp_resolutioncode src       on tsk.col_taskstp_resolutioncode = src.col_id
               inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
               inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
               inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
               inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
               inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
               inner join tbl_taskdependency td            on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FS',
                                                                                                                              'FSC',
                                                                                                                              'FSCLR',
                                                                                                                              'FSCA',
                                                                                                                              'FSCO',
                                                                                                                              'FSCEX')
               inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
               inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
               inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
               inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
               inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
               inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
               inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
               where      tsk.col_casetask = v_CaseId
                          and chldtwi.col_activity in(select col_activity
                          from    tbl_dict_taskstate)
                          and chlddts.col_activity in(select null
                          from    dual
                          union
                          select NextActivity
                          from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                          and lower(chlddim.col_code) = 'automatic_rule'
                          and(twi.col_activity <> dts.col_activity
                          or((case
                                     when td.col_processorcode is not null and twi.col_activity = dts.col_activity and mtsi.col_routedby is not null and mtsi.col_routeddate is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                     when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity and mtsi.col_routedby is not null and mtsi.col_routeddate is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id)
                                     when twi.col_activity <> dts.col_activity and mtsi.col_routedby is null and mtsi.col_routeddate is null then 0
                          end) <> 1))
                          and(chldtsk.col_id,chldmtsi.col_id) not in(select    chldtsk.col_id as ChildTaskId,
                                     chldmtsi.col_id as ChildMtsiId
                          from      (select col_id,
                                             col_taskstp_resolutioncode,
                                             col_tw_workitemtask,
                                             col_taskdict_tasksystype,
                                             col_casetask
                                     from    tbl_task
                                     where   col_casetask = v_CaseId) tsk
                          left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                          inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                          inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                          inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                          inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                          inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                          inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCO')
                          inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                          inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                          inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                          inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                          inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                          inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                          inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                          where      tsk.col_casetask = v_CaseId
                                     and chldtwi.col_activity in(select col_activity
                                     from    tbl_dict_taskstate)
                                     and chlddts.col_activity in(select null
                                     from    dual
                                     union
                                     select NextActivity
                                     from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                     and lower(chlddim.col_code) = 'automatic_rule'
                                     and((twi.col_activity = dts.col_activity /*or mtsi.col_routedby is not null*/)
                                     and(case
                                                when td.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                                when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                                     end) = 1))))
    loop
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    for rec in(select    tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and(tsk.col_id,mtsi.col_id) in(select s2.ChildTaskId as ChildTaskId,
                       s2.ChildMtsiId as ChildMtsiId
               from   (select  s1.ChildTaskId,
                                s1.ChildMtsiId,
                                row_number() over(order by s1.RowNumber) as RowNumber
                       from    (select    chldtsk.col_id as ChildTaskId,
                                           chldmtsi.col_id as ChildMtsiId,
                                           row_number() over(order by td.col_taskdependencyorder) as RowNumber
                                from      (select col_id,
                                                   col_taskstp_resolutioncode,
                                                   col_tw_workitemtask,
                                                   col_taskdict_tasksystype,
                                                   col_casetask
                                           from    tbl_task
                                           where   col_casetask = v_CaseId) tsk
                                left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                                inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                                inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                                inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                                inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                                inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                                inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCEX')
                                inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                                inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                                inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                                inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                                inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                                inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                                inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                                where      tsk.col_casetask = v_CaseId
                                           and chldtwi.col_activity in(select col_activity
                                           from    tbl_dict_taskstate)
                                           and chlddts.col_activity in(select null
                                           from    dual
                                           union
                                           select NextActivity
                                           from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                           and lower(chlddim.col_code) = 'automatic_rule'
                                           and((twi.col_activity = dts.col_activity
                                           and chldmtsi.col_routedby is null)
                                           and(case
                                                      when td.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                                      when chldmtsi.col_processorcode is not null and twi.col_activity = dts.col_activity then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                                           end) = 1)
                                union all
                                select     chldtsk.col_id as ChildTaskId,
                                           chldmtsi.col_id as ChildMtsiId,
                                           999999 as RowNumber
                                from      (select col_id,
                                                   col_taskstp_resolutioncode,
                                                   col_tw_workitemtask,
                                                   col_taskdict_tasksystype,
                                                   col_casetask
                                           from    tbl_task
                                           where   col_casetask = v_CaseId) tsk
                                left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                                inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                                inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                                inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                                inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                                inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                                inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCEX')
                                inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                                inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                                inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                                inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                                inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                                inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                                inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                                where      tsk.col_casetask = v_CaseId
                                           and chldtwi.col_activity in(select col_activity
                                           from    tbl_dict_taskstate)
                                           and chlddts.col_activity in(select null
                                           from    dual
                                           union
                                           select NextActivity
                                           from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                           and lower(chlddim.col_code) = 'automatic_rule'
                                           and twi.col_activity = dts.col_activity
                                           and chldmtsi.col_routedby is null
                                           and td.col_isdefault = 1) s1) s2
               where   s2.RowNumber = 1))
    loop
        for rec2 in(select    chldtsk2.col_id as ChildTaskId,
                   chldmtsi2.col_id as ChildMtsiId
        from       tbl_task tsk
        inner join tbl_map_taskstateinitiation mtsi      on tsk.col_id = mtsi.col_map_taskstateinittask
        inner join tbl_taskdependency td                 on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCEX')
        inner join tbl_map_taskstateinitiation chldmtsi  on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
        inner join tbl_task chldtsk                      on chldmtsi.col_map_taskstateinittask = chldtsk.col_id
        inner join tbl_taskdependency td2                on mtsi.col_id = td2.col_tskdpndprnttskstateinit and td.col_type in('FSCEX')
        inner join tbl_map_taskstateinitiation chldmtsi2 on td2.col_tskdpndchldtskstateinit = chldmtsi2.col_id
        inner join tbl_task chldtsk2                     on chldmtsi2.col_map_taskstateinittask = chldtsk2.col_id
        where      chldtsk.col_id = rec.TaskId)
        loop
            update tbl_map_taskstateinitiation
            set    col_routedby = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'),
                   col_routeddate = sysdate
            where  col_id = rec2.ChildMtsiId;
        
        end loop;
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    for rec in(select    tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and(tsk.col_id,mtsi.col_id) in(select s1.ChildTaskId,
                       s1.ChildMTSIId
               from   (select    chldtsk.col_id as ChildTaskId,
                                  tsk.col_id as ParentTaskId,
                                  td.col_id as TaskDependencyId,
                                  chlddts.col_activity as ChildTaskTargetActivity,
                                  mtsi.col_id as MTSIId,
                                  mtsi.col_routeddate as ParentTaskRouteddate,
                                  chldmtsi.col_id as ChildMTSIId,
                                  row_number() over(order by mtsi.col_routeddate desc) as RowNumber
                       from      (select col_id,
                                          col_taskstp_resolutioncode,
                                          col_tw_workitemtask,
                                          col_taskdict_tasksystype,
                                          col_casetask
                                  from    tbl_task
                                  where   col_casetask = v_CaseId) tsk
                       left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                       inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                       inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                       inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                       inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                       inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                       inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCIN')
                       inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                       inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                       inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                       inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                       inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                       inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                       inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                                  --left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                       where      tsk.col_casetask = v_CaseId
                                  and mtsi.col_routeddate is not null
                                  and chldtwi.col_activity in(select col_activity
                                  from    tbl_dict_taskstate)
                                  and chlddts.col_activity in(select null
                                  from    dual
                                  union
                                  select NextActivity
                                  from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                  and lower(chlddim.col_code) = 'automatic_rule'
                                  and((twi.col_activity = dts.col_activity
                                  or mtsi.col_routedby is null
                                  or mtsi.col_routeddate is null)
                                  and(case
                                             when td.col_processorcode is not null then f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                             when chldmtsi.col_processorcode is not null then f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id) else 1
                                  end) = 1)) s1)
    order by   TaskId)
    loop
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    for rec in(select    tsk.col_id as TaskId,
               dts.col_activity as twTargetActivity,
               mtsi.col_id as TaskStateInitId,
               mtsi.col_assignprocessorcode as TaskStateInitAssignProc
    from       tbl_task tsk
    inner join tbl_tw_workitem twi              on tsk.col_tw_workitemtask = twi.col_id
    inner join tbl_dict_tasksystype dtst        on tsk.col_taskdict_tasksystype = dtst.col_id
    inner join tbl_map_taskstateinitiation mtsi on tsk.col_id = mtsi.col_map_taskstateinittask
    inner join tbl_dict_taskstate dts           on mtsi.col_map_tskstinit_tskst = dts.col_id
    inner join tbl_dict_initmethod dim          on mtsi.col_map_tskstinit_initmtd = dim.col_id
    inner join tbl_dict_tasktransition dtt      on twi.col_tw_workitemdict_taskstate = dtt.col_sourcetasktranstaskstate and dts.col_id = dtt.col_targettasktranstaskstate and nvl(dtt.col_manualonly,0) = 0
    where      tsk.col_casetask = v_CaseId
               --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
               and twi.col_activity in(select col_activity
               from    tbl_dict_taskstate)
               and lower(dim.col_code) = 'automatic_rule'
               and dts.col_activity in(select null
               from    dual
               union
               select NextActivity
               from   table(f_DCM_getNextActivityList2(TaskId => tsk.col_id)))
               and(tsk.col_id,mtsi.col_id) in(select s1.ChildTaskId,
                       s1.ChildMTSIId
               from   (select    chldtsk.col_id as ChildTaskId,
                                  tsk.col_id as ParentTaskId,
                                  td.col_id as TaskDependencyId,
                                  chlddts.col_activity as ChildTaskTargetActivity,
                                  mtsi.col_id as MTSIId,
                                  mtsi.col_routeddate as ParentTaskRouteddate,
                                  chldmtsi.col_id as ChildMTSIId,
                                  row_number() over(order by mtsi.col_routeddate desc) as RowNumber
                       from      (select col_id,
                                          col_taskstp_resolutioncode,
                                          col_tw_workitemtask,
                                          col_taskdict_tasksystype,
                                          col_casetask
                                  from    tbl_task
                                  where   col_casetask = v_CaseId) tsk
                       left join  tbl_stp_resolutioncode src           on tsk.col_taskstp_resolutioncode = src.col_id
                       inner join tbl_tw_workitem twi                  on tsk.col_tw_workitemtask = twi.col_id
                       inner join tbl_dict_tasksystype dtst            on tsk.col_taskdict_tasksystype = dtst.col_id
                       inner join tbl_map_taskstateinitiation mtsi     on tsk.col_id = mtsi.col_map_taskstateinittask
                       inner join tbl_dict_taskstate dts               on mtsi.col_map_tskstinit_tskst = dts.col_id
                       inner join tbl_dict_initmethod dim              on mtsi.col_map_tskstinit_initmtd = dim.col_id
                       inner join tbl_taskdependency td                on mtsi.col_id = td.col_tskdpndprnttskstateinit and td.col_type in('FSCP')
                       inner join tbl_map_taskstateinitiation chldmtsi on td.col_tskdpndchldtskstateinit = chldmtsi.col_id
                       inner join tbl_dict_taskstate chlddts           on chldmtsi.col_map_tskstinit_tskst = chlddts.col_id
                       inner join tbl_task chldtsk                     on chldmtsi.col_map_taskstateinittask = chldtsk.col_id and chldtsk.col_casetask = v_CaseId
                       inner join tbl_tw_workitem chldtwi              on chldtsk.col_tw_workitemtask = chldtwi.col_id
                       inner join tbl_dict_tasksystype chlddtst        on chldtsk.col_taskdict_tasksystype = chlddtst.col_id
                       inner join tbl_dict_initmethod chlddim          on chldmtsi.col_map_tskstinit_initmtd = chlddim.col_id
                       inner join tbl_dict_tasktransition dtt          on dtt.col_sourcetasktranstaskstate = chldtwi.col_tw_workitemdict_taskstate and dtt.col_targettasktranstaskstate = chlddts.col_id and nvl(dtt.col_manualonly,0) = 0
                                  --left  join tbl_autoruleparameter chldarp on chldmtsi.col_id = chldarp.col_ruleparam_taskstateinit
                       where      tsk.col_casetask = v_CaseId
                                  and mtsi.col_routeddate is not null
                                  and chldtwi.col_activity in(select col_activity
                                  from    tbl_dict_taskstate)
                                  and chlddts.col_activity in(select null
                                  from    dual
                                  union
                                  select NextActivity
                                  from   table(f_DCM_getNextActivityList2(TaskId => chldtsk.col_id)))
                                  and lower(chlddim.col_code) = 'automatic_rule'
                                  and((twi.col_activity = dts.col_activity
                                  or mtsi.col_routedby is null
                                  or mtsi.col_routeddate is null))) s1)
    order by   TaskId)
    loop
        v_result := f_DCM_routeCaseTaskFn(CaseId => v_CaseId,
                                          TaskId => rec.TaskId,
                                          TaskStateInitAssignProc => rec.TaskStateInitAssignProc,
                                          TaskStateInitId => rec.TaskStateInitId,
                                          TwTargetActivity => rec.twTargetActivity);
        if v_result = -1 then
            return -1;
        elsif v_result = -2 then
            exit;
        else
            v_CaseInvalid := v_result;
        end if;
    end loop;
    if v_CaseInvalid = 1 then
        v_CaseInvalid := 0;
        v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                         Location => 'Before recurrent call to DCM_routeCaseTasksFn3',
                                         Message => 'Case ' || to_char(v_CaseId) || ' before reccurent call to DCM_routeCaseTasksFn3',
                                         Rule => 'DCM_routeCaseTasksFn3',
                                         TaskId => null);
        v_result := f_DCM_routeCaseTasksFn3(CaseId => v_CaseId);
        v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                         Location => 'After recurrent call to DCM_routeCaseTasksFn3',
                                         Message => 'Case ' || to_char(v_CaseId) || ' after reccurent call to DCM_routeCaseTasksFn3',
                                         Rule => 'DCM_routeCaseTasksFn3',
                                         TaskId => null);
    end if;
    v_result := f_DBG_createDBGTrace(CaseId => v_CaseId,
                                     Location => 'DCM_routeCaseTasksFn3 end',
                                     Message => 'DCM_routeCaseTasksFn3 end for case ' || to_char(v_CaseId),
                                     Rule => 'DCM_routeCaseTasksFn3',
                                     TaskId => null);
end;