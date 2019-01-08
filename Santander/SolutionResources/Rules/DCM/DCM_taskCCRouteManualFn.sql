DECLARE
    v_TaskId       INTEGER;
    v_WorkbasketId INTEGER;
    v_ResolutionId INTEGER;
    v_target nvarchar2(255) ;
    v_state nvarchar2(255) ;
    v_sysdate DATE;
    v_IsValid NUMBER;
    v_result  NUMBER;
    v_result2 nvarchar2(255) ;
    v_TaskId2 INTEGER;
    v_TaskBsId nvarchar2(255) ;
    v_TaskName nvarchar2(255) ;
    v_TaskSysType nvarchar2(255) ;
    v_TaskType nvarchar2(255) ;
    v_TaskDateAssigned DATE;
    v_TaskDateClosed   DATE;
    v_TaskDepth        INTEGER;
    v_TaskDescription NCLOB;
    v_twId INTEGER;
    v_Message NCLOB;
    v_DateEventName nvarchar2(255) ;
    v_DebugSession nvarchar2(255) ;
    v_resolutionAssigned NUMBER;
    v_taskStateId         NUMBER; 
    
BEGIN
    v_TaskId := :TaskId;
    v_WorkbasketId := :WorkbasketId;
    v_ResolutionId := :ResolutionId;
    v_target := :Target;
    v_sysdate := SYSDATE;
    v_IsValid := 1;
    v_DebugSession := f_DBG_createDBGSession(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                             CaseTypeId => f_dcm_getcasetypeforcase(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId)),
                                             ProcedureId => NULL) ;
    v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => v_TaskId),
                                     Location => 'DCM_taskRouteManualFn begin',
                                     MESSAGE => 'Before routing task ' || TO_CHAR(v_TaskId),
                                     Rule => 'DCM_taskRouteManualFn',
                                     TaskId => v_TaskId) ;
    BEGIN
        SELECT twi.col_activity
        INTO v_state
        FROM tbl_taskcc tsk
            INNER JOIN tbl_tw_workitemcc twi ON tsk.col_tw_workitemcctaskcc = twi.col_id
        WHERE tsk.col_id = v_TaskId;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :ErrorCode := 104;
        :ErrorMessage := 'Task not found';
        RETURN -1;
    END;
    BEGIN
        SELECT col_activity
        INTO v_result2
        FROM tbl_dict_taskstate
        WHERE col_activity = v_state
            AND NVL(col_stateconfigtaskstate,0) =
            (
                SELECT NVL(col_stateconfigtasksystype,0)
                FROM tbl_dict_tasksystype
                WHERE col_id =
                    (
                        SELECT col_taskccdict_tasksystype
                        FROM tbl_taskcc
                        WHERE col_id = v_TaskId
                    )
            ) ;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :ErrorCode := 105;
        :ErrorMessage := 'Task state undefined';
        RETURN -1;
    END;
    BEGIN
        SELECT v_target
        INTO v_target
        FROM dual
        WHERE v_target IN
            (
                SELECT NextActivity
                FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
            ) ;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ErrorCode := 111;
        ErrorMessage := 'Task cannot be sent from state ' || v_state || ' to state ' || v_target;
        RETURN -1;
    END;
    v_state := v_target;
    BEGIN
        SELECT col_activity
        INTO v_result2
        FROM tbl_dict_taskstate
        WHERE col_activity = v_state
            AND NVL(col_stateconfigtaskstate,0) =
            (
                SELECT NVL(col_stateconfigtasksystype,0)
                FROM tbl_dict_tasksystype
                WHERE col_id =
                    (
                        SELECT col_taskccdict_tasksystype
                        FROM tbl_taskcc
                        WHERE col_id = v_TaskId
                    )
            ) ;
    
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        :ErrorCode := 107;
        :ErrorMessage := 'Task next state undefined';
        RETURN -1;
    END;
    FOR rec IN
    (
        --FIRST FIND RECORDS WITH INITIATION TYPE 'MANUAL_CONFIG' THAT CAN BE STARTED BY DEPENDENCY TYPES 'FS', 'FSO', 'SS'
        SELECT s1.TaskId AS TaskId,
            s1.TaskBsId AS TaskBsId,
            s1.TaskName AS TaskName,
            s1.TaskSysType AS TaskSysType,
            s1.TaskType AS TaskType,
            s1.TaskDateAssigned AS TaskDateAssigned,
            s1.TaskDateClosed AS TaskDateClosed,
            s1.TaskDepth AS TaskDepth,
            s1.TaskDescription AS TaskDescription,
            s1.twId AS TWId,
            s1.CaseId AS CaseId,
            s1.TaskStateId AS TaskStateId,
            s1.AssignProcessorCode AS AssignProcessorCode
        FROM(
                SELECT tsk.col_id AS TaskId,
                    tsk.col_taskid AS TaskBsId,
                    tsk.col_name AS TaskName,
                    dtst.col_code AS TaskSysType,
                    tsk.col_type AS Tasktype,
                    tsk.col_dateassigned AS TaskDateAssigned,
                    tsk.col_dateclosed AS TaskDateClosed,
                    tsk.col_depth AS TaskDepth,
                    tsk.col_description AS TaskDescription,
                    twi.col_id AS twId,
                    tsk.col_casecctaskcc AS CaseId,
                    mtsi.col_id AS TaskStateId,
                    mtsi.col_assignprocessorcode AS AssignProcessorCode
                FROM tbl_taskcc tsk
                    INNER JOIN tbl_tw_workitemcc twi        ON tsk.col_tw_workitemcctaskcc = twi.col_id
                    INNER JOIN tbl_dict_tasksystype dtst    ON tsk.col_taskccdict_tasksystype = dtst.col_id
                    INNER JOIN tbl_map_taskstateinitcc mtsi ON tsk.col_id = mtsi.col_map_taskstateinitcctaskcc
                    INNER JOIN tbl_dict_taskstate dts       ON mtsi.col_map_tskstinitcc_tskst = dts.col_id
                    INNER JOIN tbl_dict_initmethod dim      ON mtsi.col_map_tskstinitcc_initmtd = dim.col_id
                WHERE tsk.col_id = v_TaskId
                    --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                    AND v_target IN
                    (
                        SELECT NextActivity
                        FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                    )
                    AND
                    (
                        (
                            lower(dim.col_code) = 'manual_config'
                        )
                        OR
                        (
                            lower(dim.col_code) = 'automatic_config'
                        )
                    )
                    AND dts.col_activity = v_state
                    --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY FINISH-TO-START DEPENDENCY TYPE (FS) THAT ARE NOT CLOSED
                    --TASK IS CONSIDERED NOT CLOSED IF TASK STATE IS NOT 'root_TSK_Status_CLOSED'
                    AND tsk.col_id NOT IN
                    (
                        SELECT tsic.col_map_taskstateinitcctaskcc
                            --SELECT FROM TASK DEPENDENCY
                        FROM tbl_taskdependencycc td
                            --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                            INNER JOIN tbl_map_taskstateinitcc tsip ON td.col_taskdpprntcctaskstinitcc = tsip.col_id
                            --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                            INNER JOIN tbl_map_taskstateinitcc tsic ON td.col_taskdpchldcctaskstinitcc = tsic.col_id
                            --JOIN PARENT TASK
                            INNER JOIN tbl_taskcc tskp ON tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                            --JOIN CHILD TASK
                            INNER JOIN tbl_taskcc tskc ON tsic.col_map_taskstateinitcctaskcc = tskc.col_id
                            --JOIN PARENT WORKITEM
                            INNER JOIN tbl_tw_workitemcc twip ON tskp.col_tw_workitemcctaskcc = twip.col_id
                            --JOIN CHILD WORKITEM
                            INNER JOIN tbl_tw_workitemcc twic ON tskc.col_tw_workitemcctaskcc = twic.col_id
                            --JOIN PARENT TASK STATE
                            INNER JOIN tbl_dict_taskstate dtsp ON tsip.col_map_tskstinitcc_tskst = dtsp.col_id
                            --JOIN CHILD TASK STATE
                            INNER JOIN tbl_dict_taskstate dtsc ON tsic.col_map_tskstinitcc_tskst = dtsc.col_id
                        WHERE tskc.col_id = v_TaskId
                            --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                            AND dtsc.col_activity = v_state
                            AND v_target IN
                            (
                                SELECT NextActivity
                                FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                            )
                            AND
                            (
                                twip.col_activity <> dtsp.col_activity
                                AND tsip.col_routedby IS NULL
                                AND tsip.col_routeddate IS NULL
                            )
                            --FILTER DEPENDENCY TO TYPE 'FS' ONLY
                            AND td.col_type = 'FS'
                    )
                    --CHECK THAT TASKS IN SELECT RESULT ITEMS ARE VALID ACCORDING TO "FSO" DEPENDENCY TYPE
                    --"FSO" DEPENDENY IS FINISH-TO-START FLAVOR WITH AT LEAST ONE OF PARENT TASKS IS CLOSED
                    --THIS MEANS THAT EITHER THOSE TASKS ARE NOT DEPENDENT FROM ANY OTHER TASKS (PARENT TASKS) BY "FSO" DEPENDENCY TYPE
                    --OR IF THEY HAVE SUCH DEPENDENCY, AT LEAST ONE PARENT TASK IS IN 'root_TSK_Status_CLOSED' STATE
                    AND
                    (
                        (
                            SELECT COUNT(*)
                            FROM(
                                    SELECT tsic.col_map_taskstateinitcctaskcc,
                                        tskc.col_id AS TaskId
                                    FROM tbl_taskdependencycc td
                                        --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                        INNER JOIN tbl_map_taskstateinitcc tsip ON td.col_taskdpprntcctaskstinitcc = tsip.col_id
                                        --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                                        INNER JOIN tbl_map_taskstateinitcc tsic ON td.col_taskdpchldcctaskstinitcc = tsic.col_id
                                        --JOIN PARENT TASK
                                        INNER JOIN tbl_taskcc tskp ON tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                                        --JOIN CHILD TASK
                                        INNER JOIN tbl_taskcc tskc ON tsic.col_map_taskstateinitcctaskcc = tskc.col_id
                                        --JOIN PARENT WORKITEM
                                        INNER JOIN tbl_tw_workitemcc twip ON tskp.col_tw_workitemcctaskcc = twip.col_id
                                        --JOIN CHILD WORKITEM
                                        INNER JOIN tbl_tw_workitemcc twic ON tskc.col_tw_workitemcctaskcc = twic.col_id
                                        --JOIN PARENT TASK STATE
                                        INNER JOIN tbl_dict_taskstate dtsp ON tsip.col_map_tskstinitcc_tskst = dtsp.col_id
                                        --JOIN CHILD TASK STATE
                                        INNER JOIN tbl_dict_taskstate dtsc ON tsic.col_map_tskstinitcc_tskst = dtsc.col_id
                                    WHERE tskc.col_id = v_TaskId
                                        --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                        AND dtsc.col_activity = v_state
                                        --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                                        AND td.col_type = 'FSO'
                                )
                                s1
                            WHERE s1.TaskId = tsk.col_id
                        )
                        = 0
                        OR
                        (
                            SELECT COUNT(*)
                            FROM(
                                    SELECT tsic.col_map_taskstateinitcctaskcc,
                                        tskc.col_id AS TaskId
                                    FROM tbl_taskdependencycc td
                                        --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                                        INNER JOIN tbl_map_taskstateinitcc tsip ON td.col_taskdpprntcctaskstinitcc = tsip.col_id
                                        --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                                        INNER JOIN tbl_map_taskstateinitcc tsic ON td.col_taskdpchldcctaskstinitcc = tsic.col_id
                                        --JOIN PARENT TASK
                                        INNER JOIN tbl_taskcc tskp ON tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                                        --JOIN CHILD TASK
                                        INNER JOIN tbl_taskcc tskc ON tsic.col_map_taskstateinitcctaskcc = tskc.col_id
                                        --JOIN PARENT WORKITEM
                                        INNER JOIN tbl_tw_workitemcc twip ON tskp.col_tw_workitemcctaskcc = twip.col_id
                                        --JOIN CHILD WORKITEM
                                        INNER JOIN tbl_tw_workitemcc twic ON tskc.col_tw_workitemcctaskcc = twic.col_id
                                        --JOIN PARENT TASK STATE
                                        INNER JOIN tbl_dict_taskstate dtsp ON tsip.col_map_tskstinitcc_tskst = dtsp.col_id
                                        --JOIN CHILD TASK STATE
                                        INNER JOIN tbl_dict_taskstate dtsc ON tsic.col_map_tskstinitcc_tskst = dtsc.col_id
                                    WHERE tskc.col_id = v_TaskId
                                        --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                                        AND dtsc.col_activity = v_state
                                        AND twip.col_activity = dtsp.col_activity
                                        --FILTER DEPENDENCY TO TYPE 'FSO' ONLY
                                        AND td.col_type = 'FSO'
                                )
                                s2
                            WHERE s2.TaskId = tsk.col_id
                        )
                        > 0
                    )
                    --THOSE TASKS MUST NOT CONTAIN TASKS (CHILD TASKS) THAT ARE DEPENDENT ON OTHER TASKS (PARENT TASKS) BY START-TO-START DEPENDENCY TYPE (SS) THAT ARE NOT STARTED
                    --TASK IS CONSIDERED NOT STARTED IF EITHER TASK STATE IS 'root_TSK_Status_NEW' OR TASK DATE ASSIGNED IS NULL
                    AND tsk.col_id NOT IN
                    (
                        SELECT tsic.col_map_taskstateinitcctaskcc
                            --SELECT FROM TASK DEPENDENCY
                        FROM tbl_taskdependencycc td
                            --JOIN TASK INITIATION RECORDS FOR PARENT TASK
                            INNER JOIN tbl_map_taskstateinitcc tsip ON td.col_taskdpprntcctaskstinitcc = tsip.col_id
                            --JOIN TASK INITIATION RECORDS FOR CHILD TASK
                            INNER JOIN tbl_map_taskstateinitcc tsic ON td.col_taskdpchldcctaskstinitcc = tsic.col_id
                            --JOIN PARENT TASK
                            INNER JOIN tbl_taskcc tskp ON tsip.col_map_taskstateinitcctaskcc = tskp.col_id
                            --JOIN CHILD TASK
                            INNER JOIN tbl_taskcc tskc ON tsic.col_map_taskstateinitcctaskcc = tskc.col_id
                            --JOIN PARENT WORKITEM
                            INNER JOIN tbl_tw_workitemcc twip ON tskp.col_tw_workitemcctaskcc = twip.col_id
                            --JOIN CHILD WORKITEM
                            INNER JOIN tbl_tw_workitemcc twic ON tskc.col_tw_workitemcctaskcc = twic.col_id
                            --JOIN PARENT TASK STATE
                            INNER JOIN tbl_dict_taskstate dtsp ON tsip.col_map_tskstinitcc_tskst = dtsp.col_id
                            --JOIN CHILD TASK STATE
                            INNER JOIN tbl_dict_taskstate dtsc ON tsic.col_map_tskstinitcc_tskst = dtsc.col_id
                        WHERE tskc.col_id = v_TaskId
                            --FILTER CHILD TASK INITIATION RECORDS TO STATE 'root_TSK_Status_STARTED'
                            AND dtsc.col_activity = v_state
                            AND v_target IN
                            (
                                SELECT NextActivity
                                FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                            )
                            AND
                            (
                                twip.col_activity NOT IN
                                (
                                    SELECT nexttaskactivity
                                    FROM TABLE(f_DCM_getNextTaskStates(StartState => dtsp.col_activity))
                                )
                                AND twip.col_activity <> dtsp.col_activity
                            )
                            --FILTER DEPENDENCY TO TYPE 'SS' ONLY
                            AND td.col_type = 'SS'
                    )
                UNION ALL
                --ADD RECORDS WITH INITIATION TYPE 'MANUAL'
                SELECT tsk.col_id AS TaskId,
                    tsk.col_taskid AS TaskBsId,
                    tsk.col_name AS Taskname,
                    dtst.col_code AS TaskSysType,
                    tsk.col_type AS TaskType,
                    tsk.col_dateassigned AS TaskDateAssigned,
                    tsk.col_dateclosed AS TaskDateClosed,
                    tsk.col_depth AS TaskDepth,
                    tsk.col_description AS TaskDescription,
                    twi.col_id AS twId,
                    tsk.col_casecctaskcc AS CaseId,
                    mtsi.col_id AS TaskStateId,
                    mtsi.col_assignprocessorcode AS AssignProcessorCode
                FROM tbl_taskcc tsk
                    INNER JOIN tbl_tw_workitemcc twi     ON tsk.col_tw_workitemcctaskcc = twi.col_id
                    INNER JOIN tbl_dict_tasksystype dtst ON tsk.col_taskccdict_tasksystype = dtst.col_id
                    
                    INNER JOIN tbl_map_taskstateinitcc mtsi ON tsk.col_id = mtsi.col_map_taskstateinitcctaskcc
                    INNER JOIN tbl_dict_taskstate dts       ON mtsi.col_map_tskstinitcc_tskst = dts.col_id
                    INNER JOIN tbl_dict_initmethod dim      ON mtsi.col_map_tskstinitcc_initmtd = dim.col_id
                
                WHERE tsk.col_id = v_TaskId
                    --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                    AND v_target IN
                    (
                        SELECT NextActivity
                        FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                    )
                    AND lower(dim.col_code) IN('manual',
                                               'automatic')
                    AND dts.col_activity = v_state
                UNION ALL
                --ADD RECORDS WITH INITIATION TYPE 'MANUL_RULE'
                SELECT tsk.col_id AS TaskId,
                    tsk.col_taskid AS TaskBsId,
                    tsk.col_name AS TaskName,
                    dtst.col_code AS TaskSysType,
                    tsk.col_type AS Tasktype,
                    tsk.col_dateassigned AS TaskDateAssigned,
                    tsk.col_dateclosed AS TaskDateClosed,
                    tsk.col_depth AS TaskDepth,
                    tsk.col_description AS TaskDescription,
                    twi.col_id AS twId,
                    tsk.col_casecctaskcc AS CaseId,
                    mtsi.col_id AS TaskStateId,
                    mtsi.col_assignprocessorcode AS AssignProcessorCode
                FROM tbl_taskcc tsk
                    INNER JOIN tbl_tw_workitemcc twi        ON tsk.col_tw_workitemcctaskcc = twi.col_id
                    INNER JOIN tbl_dict_tasksystype dtst    ON tsk.col_taskccdict_tasksystype = dtst.col_id
                    INNER JOIN tbl_map_taskstateinitcc mtsi ON tsk.col_id = mtsi.col_map_taskstateinitcctaskcc
                    INNER JOIN tbl_dict_taskstate dts       ON mtsi.col_map_tskstinitcc_tskst = dts.col_id
                    INNER JOIN tbl_dict_initmethod dim      ON mtsi.col_map_tskstinitcc_initmtd = dim.col_id
                WHERE tsk.col_id = v_TaskId
                    --TASKS WITH STATUS 'root_TSK_Status_NEW' CAN BE STARTED
                    AND v_target IN
                    (
                        SELECT NextActivity
                        FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                    )
                    AND lower(dim.col_code) IN('manual_rule',
                                               'automatic_rule')
                    AND dts.col_activity = v_state
                    AND tsk.col_id NOT IN
                    (
                        SELECT chldtsk.col_id
                        FROM tbl_taskcc tsk
                            LEFT JOIN tbl_stp_resolutioncode src    ON tsk.col_taskccstp_resolutioncode = src.col_id
                            INNER JOIN tbl_tw_workitemcc twi        ON tsk.col_tw_workitemcctaskcc = twi.col_id
                            INNER JOIN tbl_dict_tasksystype dtst    ON tsk.col_taskccdict_tasksystype = dtst.col_id
                            INNER JOIN tbl_map_taskstateinitcc mtsi ON tsk.col_id = mtsi.col_map_taskstateinitcctaskcc
                            INNER JOIN tbl_dict_taskstate dts       ON mtsi.col_map_tskstinitcc_tskst = dts.col_id
                            INNER JOIN tbl_dict_initmethod dim      ON mtsi.col_map_tskstinitcc_initmtd = dim.col_id
                            INNER JOIN tbl_taskdependencycc td      ON mtsi.col_id = td.col_taskdpprntcctaskstinitcc AND td.col_type IN('FSC',
                                                                                                                                        'FS',
                                                                                                                                        'FSCLR')
                            INNER JOIN tbl_map_taskstateinitcc chldmtsi ON td.col_taskdpchldcctaskstinitcc = chldmtsi.col_id
                            INNER JOIN tbl_dict_taskstate chlddts       ON chldmtsi.col_map_tskstinitcc_tskst = chlddts.col_id
                            INNER JOIN tbl_taskcc chldtsk               ON chldmtsi.col_map_taskstateinitcctaskcc = chldtsk.col_id
                            INNER JOIN tbl_tw_workitemcc chldtwi        ON chldtsk.col_tw_workitemcctaskcc = chldtwi.col_id
                            INNER JOIN tbl_dict_tasksystype chlddtst    ON chldtsk.col_taskccdict_tasksystype = chlddtst.col_id
                            INNER JOIN tbl_dict_initmethod chlddim      ON chldmtsi.col_map_tskstinitcc_initmtd = chlddim.col_id
                            LEFT JOIN tbl_autoruleparamcc chldarp       ON chldmtsi.col_id = chldarp.col_ruleparcc_taskstateinitcc
                        WHERE chldtsk.col_id = v_TaskId
                            AND v_target IN
                            (
                                SELECT NextActivity
                                FROM TABLE(f_DCM_getNextActivityListCC(TaskId => v_TaskId))
                            )
                            AND chlddts.col_activity = v_state
                            AND lower(chlddim.col_code) IN('manual_rule',
                                                           'automatic_rule')
                            AND
                            (
                                (
                                    twi.col_activity <> dts.col_activity
                                    AND mtsi.col_routedby IS NULL
                                    AND mtsi.col_routeddate IS NULL
                                )
                                OR
                                    (
                                        CASE
                                            WHEN td.col_processorcode IS NOT NULL
                                                THEN f_DCM_invokeTaskProcessor2(td.col_processorcode,td.col_id)
                                            WHEN chldmtsi.col_processorcode IS NOT NULL
                                                THEN f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode,chldmtsi.col_id)
                                            ELSE 1
                                        END
                                    )
                                <> 1
                            )
                    )
                    -- and f_DCM_invokeTaskProcessor(chldmtsi.col_processorcode, chldmtsi.col_id) = 1)
            )
            s1
    )
    LOOP
        --SAVE RULE PARAMETERS RESOLUTION AND WORKBASKET FOR PROCESSING BY VALIDATION EVENTS
        UPDATE
            tbl_taskcc
        SET col_taskccworkbasket_param = v_WorkbasketId,
            col_taskccresolcode_param = v_ResolutionId
        WHERE col_id = rec.TaskId;
        
        --BEFORE TRANSITION VALIDATION EVENTS
        v_DebugSession := f_DBG_createDBGSession(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                                 CaseTypeId => f_dcm_getcasetypeforcase(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId)),
                                                 ProcedureId => NULL) ;
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                         Location => 'Before processing of before routing validation events',
                                         MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before processing of before routing to ' || v_state || ' validation events',
                                         Rule => 'DCM_taskRouteManualFn',
                                         TaskId => rec.TaskId) ;
        v_result := f_DCM_processEventCC2(MESSAGE => v_Message,
                                          NextTaskId => rec.TaskId,
                                          EventState => v_state,
                                          IsValid => v_IsValid) ;
        v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                         Location => 'After processing of before routing validation events',
                                         MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after processing of before routing to ' || v_state || ' validation events',
                                         Rule => 'DCM_taskRouteManualFn',
                                         TaskId => rec.TaskId) ;
        IF NVL(v_IsValid,0) = 0 THEN
            :ErrorCode := 112;
            :ErrorMessage := v_Message;
            RETURN -1;
        END IF;
        IF v_IsValid = 1 THEN
            v_resolutionAssigned := 0;
            --BEFORE TRANSITION ACTION EVENTS
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'Before processing of before routing action events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before processing of before routing to ' || v_state || ' action events',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            v_result := f_DCM_processEventCC5(MESSAGE => v_Message,
                                              NextTaskId => rec.TaskId,
                                              EventState => v_state,
                                              IsValid => v_IsValid) ;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'After processing of before routing action events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after processing of before routing to ' || v_state || ' action events',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            BEGIN
                FOR rec2 IN
                (
                    SELECT ts.col_id AS TaskStateId,
                        ts.col_code AS TaskStateCode,
                        ts.col_name AS TaskStateName,
                        ts.col_activity AS TaskStateActivity,
                        tst.col_id AS TaskStateSetupId,
                        tst.col_name AS TaskStateSetupName,
                        tst.col_code AS TaskStateSetupCode,
                        tst.col_forcednull AS ForcedNull,
                        tst.col_forcedoverwrite AS ForcedOverwrite,
                        tst.col_notnulloverwrite AS NotNullOverwrite,
                        tst.col_nulloverwrite AS NullOverwrite
                    FROM tbl_dict_taskstate ts
                        INNER JOIN tbl_dict_taskstatesetup tst ON ts.col_id = tst.col_taskstatesetuptaskstate
                    WHERE ts.col_activity = v_state
                )
                LOOP
                    IF rec2.taskstatesetupcode = 'DATESTARTED' THEN
                        UPDATE
                            tbl_taskcc
                        SET col_datestarted = v_sysdate
                        WHERE col_id = rec.TaskId;
                    
                    elsif rec2.taskstatesetupcode = 'DATEASSIGNED' THEN
                        IF rec2.ForcedNull = 1 THEN
                            UPDATE
                                tbl_taskcc
                            SET col_dateassigned = NULL
                            WHERE col_id = rec.TaskId;
                        
                        elsif rec2.ForcedOverwrite = 1 THEN
                            UPDATE
                                tbl_taskcc
                            SET col_dateassigned = v_sysdate
                            WHERE col_id = rec.TaskId;
                        
                        END IF;
                    elsif rec2.taskstatesetupcode = 'DATECLOSED' THEN
                        UPDATE
                            tbl_taskcc
                        SET col_dateclosed = v_sysdate
                        WHERE col_id = rec.TaskId;
                    
                    elsif rec2.taskstatesetupcode = 'WORKBASKET' THEN
                        IF rec2.ForcedNull = 1 THEN
                            UPDATE
                                tbl_taskcc
                            SET col_taskccpreviousworkbasket = col_taskccppl_workbasket,
                                col_taskccppl_workbasket = NULL
                            WHERE col_id = rec.TaskId;
                        
                        elsif rec2.ForcedOverwrite = 1 THEN
                            UPDATE
                                tbl_taskcc
                            SET col_taskccpreviousworkbasket = col_taskccppl_workbasket,
                                col_taskccppl_workbasket = v_WorkbasketId
                            WHERE col_id = rec.TaskId;
                        
                        END IF;
                    elsif rec2.taskstatesetupcode = 'RESOLUTION' THEN
                        UPDATE
                            tbl_taskcc
                        SET col_taskccstp_resolutioncode = v_ResolutionId
                        WHERE col_id = rec.TaskId;
                        
                        v_resolutionAssigned := 1;
                    END IF;
                END LOOP;
                IF(rec.AssignProcessorCode IS NOT NULL)
                    AND
                    (
                        v_WorkbasketId IS NULL
                    )
                    THEN
                    v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                                     Location => 'Before assigment',
                                                     MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before assignment by ' || rec.AssignProcessorCode,
                                                     Rule => 'DCM_taskRouteManualFn',
                                                     TaskId => rec.TaskId) ;
                    v_result := f_DCM_invokeTaskAssignProc2(ProcessorName => rec.AssignProcessorCode,
                                                            State => v_state,
                                                            TaskId => rec.TaskId) ;
                    v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                                     Location => 'After assigment',
                                                     MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after assignment by ' || rec.AssignProcessorCode,
                                                     Rule => 'DCM_taskRouteManualFn',
                                                     TaskId => rec.TaskId) ;
                END IF;
                --SET TASK rec.TaskId IN CURSOR rec TO STATE v_state
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                                 Location => 'Before task ' || TO_CHAR(rec.TaskId) || ' routing',
                                                 MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before being routed to activity ' || v_state,
                                                 Rule => 'DCM_taskRouteManualFn',
                                                 TaskId => rec.TaskId) ;
                                                 
                --define a task activity
                v_taskStateId :=NULL;
                BEGIN
                  SELECT col_id INTO v_taskStateId
                  FROM tbl_dict_taskstate
                  WHERE col_activity = v_state
                      AND NVL(col_stateconfigtaskstate,0) =
                      (
                          SELECT NVL(col_stateconfigtasksystype,0)
                          FROM tbl_dict_tasksystype
                          WHERE col_id =
                              (
                                  SELECT col_taskccdict_tasksystype
                                  FROM tbl_taskcc
                                  WHERE col_id = rec.TaskId
                              )
                      );
                EXCEPTION WHEN NO_DATA_FOUND THEN v_taskStateId :=NULL;    
                END;

                UPDATE TBL_TASKCC
                SET  COL_PREVTASKCCDICT_TASKSTATE = COL_TASKCCDICT_TASKSTATE,
                     COL_TASKCCDICT_TASKSTATE = v_taskStateId
                WHERE  COL_ID =rec.TaskId;  
                
                UPDATE
                    tbl_tw_workitemcc
                SET col_activity = v_state,
                    col_tw_workitemccprevtaskst = col_tw_workitemccdict_taskst,
                    col_tw_workitemccdict_taskst =
                    (
                        SELECT col_id
                        FROM tbl_dict_taskstate
                        WHERE col_activity = v_state
                            AND NVL(col_stateconfigtaskstate,0) =
                            (
                                SELECT NVL(col_stateconfigtasksystype,0)
                                FROM tbl_dict_tasksystype
                                WHERE col_id =
                                    (
                                        SELECT col_taskccdict_tasksystype
                                        FROM tbl_taskcc
                                        WHERE col_id = rec.TaskId
                                    )
                            )
                    )
                WHERE col_id =
                    (
                        SELECT col_tw_workitemcctaskcc
                        FROM tbl_taskcc
                        WHERE col_id = rec.TaskId
                    ) ;
                
                UPDATE
                    tbl_map_taskstateinitcc
                SET col_routedby = SYS_CONTEXT('CLIENTCONTEXT','AccessSubject'),
                    col_routeddate = SYSDATE
                WHERE col_id = rec.TaskStateId;
                
                v_result := f_DCM_resetSlaEventCounter(TaskId => rec.TaskId) ;
                v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                                 Location => 'After task ' || TO_CHAR(rec.TaskId) || ' routing',
                                                 MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after being routed to activity ' || v_state,
                                                 Rule => 'DCM_taskRouteManualFn',
                                                 TaskId => rec.TaskId) ;
                v_Result := f_DCM_addTaskDateEventCCList(TaskId => rec.TaskId,
                                                         state => v_state) ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                :ErrorCode := 101;
                :ErrorMessage := 'Task start failed';
                RETURN -1;
            END;
            --CREATE NOTIFICATION
            v_result := f_DCM_createNotification(CaseId => NULL,
                                                 NotificationTypeCode => 'TASK_MOVED',
                                                 TaskId => rec.TaskId) ;
            --AFTER TRANSITION ACTION SYNCHRONOUS EVENTS
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'Before processing of --after task routing action-- synchronous events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before processing of --after task routing action-- synchronous events' || v_state,
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            v_result := f_DCM_processEventCC6(MESSAGE => v_Message,
                                              NextTaskId => rec.TaskId,
                                              EventState => v_state,
                                              IsValid => v_IsValid) ;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'After processing of --after task routing action-- synchronous events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after processing of --after task routing action-- synchronous events' || v_state,
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            IF v_resolutionAssigned = 0 THEN													  
				v_result := F_hist_createhistoryfn(
					additionalinfo => null,
					issystem       => 0,
					MESSAGE        => null,
					messagecode    => 'TaskRouted',
					targetid       => rec.TaskId,
					targettype     => 'TASK'
			   );
													  
            elsif v_resolutionAssigned = 1 THEN													  
				v_result := F_hist_createhistoryfn(
					additionalinfo => null,
					issystem       => 0,
					MESSAGE        => null,
					messagecode    => 'TaskRoutedWithResolution',
					targetid       => rec.TaskId,
					targettype     => 'TASK'
			   );
            END IF;
            --TRY TO RETURN CLOSED CASE TASKS TO STARTED WHEN CONDITION VALIDATION SUCCEEDS (DEPENDENCY TYPE 'FSCLR')
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'Before call to DCM_routeallcasetasksfn',
                                             MESSAGE => 'Before call to DCM_routeallcasetasksfn',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            v_result := f_DCM_routeAllCaseCCTasksCCFn(TaskId => rec.TaskId) ;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'After call to DCM_routeallcasetasksfn',
                                             MESSAGE => 'After call to DCM_routeallcasetasksfn',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE
            v_result := f_dcm_invalidatecase(CaseId => rec.CaseId) ;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'Before call to dcm_casequeueproc5',
                                             MESSAGE => 'Before call to dcm_casequeueproc5',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            v_result := f_dcm_casequeueproc7();
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'After call to dcm_casequeueproc5',
                                             MESSAGE => 'After call to dcm_casequeueproc5',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            --AFTER TRANSITION ACTION ASYNCHRONOUS EVENTS
            --v_result := f_dcm_registeraftereventfn(TaskId => rec.TaskId);
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'Before processing of --after task routing action-- asynchronous events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' before processing of --after task routing action-- asynchronous events' || v_state,
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            v_result := f_DCM_processEventCC7(MESSAGE => v_Message,
                                              NextTaskId => rec.TaskId,
                                              EventState => v_state,
                                              IsValid => v_IsValid) ;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'After processing of --after task routing action-- asynchronous events',
                                             MESSAGE => 'Task ' || TO_CHAR(rec.TaskId) || ' after processing of --after task routing action-- asynchronous events' || v_state,
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            IF v_target = f_dcm_getTaskNewState()
                OR
                v_target = f_dcm_getTaskStartedState() THEN
                v_result := f_dcm_statClear(TaskId => rec.TaskId) ;
            END IF;
            v_result := f_dcm_statCalc(TaskId => rec.TaskId) ;
            IF v_target = f_dcm_getTaskClosedState() THEN
                v_result := f_dcm_statUpdate(TaskId => rec.TaskId) ;
            END IF;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'DCM_taskRouteManualFn end',
                                             MESSAGE => 'After task ' || TO_CHAR(rec.TaskId) || ' routing succeeded',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            RETURN 0;
        ELSE
            v_result := f_DCM_createTaskHistoryCC2(IsSystem => 0,
                                                   MESSAGE => v_Message,
                                                   TaskId => rec.TaskId) ;
            :ErrorCode := 102;
            :ErrorMessage := v_Message;
            v_result := f_DBG_createDBGTrace(CaseId => f_DCM_findCaseByTask(TaskId => rec.TaskId),
                                             Location => 'DCM_taskRouteManualFn end',
                                             MESSAGE => 'After task ' || TO_CHAR(rec.TaskId) || ' routing failed',
                                             Rule => 'DCM_taskRouteManualFn',
                                             TaskId => rec.TaskId) ;
            RETURN -1;
        END IF;
    END LOOP;
END;