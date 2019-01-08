DECLARE
  --INPUT
  v_task_id INTEGER;

  v_Counters SYS_REFCURSOR;
  v_result   NUMBER;
BEGIN
  --INPUT
  v_task_id := :TASK_ID;

  --GET DATA IF TASKID IS PRESENT
  IF v_task_id > 0 THEN
    OPEN :CUR_DATA FOR
      SELECT tv.*,
             CASE
               WHEN (1 IN (SELECT Allowed
                             FROM TABLE(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE', p_PermissionCode => 'VIEW'))
                            WHERE CaseTypeId = (SELECT COL_CASEDICT_CASESYSTYPE FROM TBL_CASE WHERE COL_ID = tv.CASE_ID))) THEN
                1
               ELSE
                0
             END AS PERM_CASETYPE_VIEW,
             
             f_DCM_getTaskCustomData(tv.ID) AS CustomData,
             
             --CALC SLAs AND OTHER DURATIONS
             F_util_getdrtnfrmnow(tv.GoalSlaDateTime) AS GoalSlaDuration,
             F_util_getdrtnfrmnow(tv.DLineSlaDateTime) AS DLineSlaDuration,
             F_getnamefromaccesssubject(tv.createdby) AS createdby_name,
             F_util_getdrtnfrmnow(tv.createddate) AS createdduration,
             F_getnamefromaccesssubject(tv.MODIFIEDBY) AS modifiedby_name,
             F_util_getdrtnfrmnow(tv.MODIFIEDDATE) AS modifiedduration,
             f_dcm_getpageid(entity_id => tv.ID, entity_type => 'task') AS DesignerPage_Id,
             
             --task ownership
             /*             twb.CALCNAME     AS WORKBASKET_NAME,
             twb.CALCTYPE     AS WORKBASKET_TYPE_NAME,
             twb.CALCTYPECODE AS WORKBASKET_TYPE_CODE,*/
             
             --case ownership
             cwb.CALCNAME     AS CASE_WORKBASKET_NAME,
             cwb.CALCTYPE     AS CASE_WORKBASKETTYPENAME,
             cwb.CALCTYPECODE AS CASE_WORKBASKETTYPECODE,
             
             --parent task
             (SELECT COL_TASKID FROM TBL_TASK WHERE COL_ID = tv.PARENTID) AS PARENTTASK_TASKID,

				 -- get description of case	
             (SELECT col_description FROM tbl_caseext WHERE col_caseextcase = tv.CASE_ID) AS CASE_DESCRIPTION,

             --LEGACY SUPPORT
             tv.TITLE      AS TASKID,
             tv.CASE_TITLE AS CASEID
      
        FROM VW_DCM_FullTaskSla tv
      /*        LEFT JOIN VW_PPL_SimpleWorkbasket twb
      ON twb.id = tv.WORKBASKET_ID*/
        LEFT JOIN VW_PPL_SimpleWorkbasket cwb
          ON cwb.id = tv.CASE_WORKBASKETID
       WHERE tv.ID = v_task_id;
  
    -- GET ROUTING DATA
    --get next states for the task
    OPEN :CUR_AVAILTRANSITIONS FOR
      SELECT tskt.col_id         AS ID,
             tskt.col_name       AS NAME,
             tskt.col_code       AS CODE,
             tskt.col_iconcode   AS ICONCODE,
             tskts.col_activity  AS TARGET_ACTIVITY,
             tskts.col_isstart   AS TARGET_ISSTART,
             tskts.col_isfinish  AS TARGET_ISFINISH,
             tskts.col_isresolve AS TARGET_ISRESOLVE,
             tskts.col_canassign AS TARGET_CANASSIGN
        FROM tbl_dict_tasktransition tskt
        LEFT JOIN tbl_dict_taskstate tskss
          ON tskt.col_sourcetasktranstaskstate = tskss.col_id
        LEFT JOIN tbl_dict_taskstate tskts
          ON tskt.col_targettasktranstaskstate = tskts.col_id
        LEFT JOIN tbl_tw_workitem twi
          ON tskss.col_id = twi.col_tw_workitemdict_taskstate
        LEFT JOIN tbl_task tsk
          ON twi.col_id = tsk.col_tw_workitemtask
        LEFT JOIN tbl_case cs
          ON tsk.col_casetask = cs.col_id
        LEFT JOIN tbl_map_taskstateinitiation mtsi
          ON tsk.col_id = mtsi.col_map_taskstateinittask
         AND tskts.col_id = mtsi.col_map_tskstinit_tskst
        LEFT JOIN tbl_dict_initmethod dim
          ON mtsi.col_map_tskstinit_initmtd = dim.col_id
        LEFT JOIN tbl_fom_uielement uecttt
          ON tskt.col_id = uecttt.col_uielementtasktransition
         AND cs.col_casedict_casesystype = uecttt.col_uielementcasesystype
         AND tsk.col_taskdict_tasksystype = uecttt.col_uielementtasksystype
        LEFT JOIN tbl_fom_uielement uett
          ON tskt.col_id = uett.col_uielementtasktransition
         AND uett.col_uielementcasesystype IS NULL
         AND tsk.col_taskdict_tasksystype = uett.col_uielementtasksystype
        LEFT JOIN tbl_fom_uielement ue
          ON tskt.col_id = ue.col_uielementtasktransition
         AND ue.col_uielementcasesystype IS NULL
         AND ue.col_uielementtasksystype IS NULL
       WHERE CASE
               WHEN uecttt.col_id IS NOT NULL THEN
                Nvl(uecttt.col_ishidden, 0)
               WHEN uett.col_id IS NOT NULL THEN
                Nvl(uett.col_ishidden, 0)
               WHEN ue.col_id IS NOT NULL THEN
                Nvl(ue.col_ishidden, 0)
               ELSE
                0
             END = 0
         AND tsk.col_id = v_task_id
       ORDER BY tskss.col_defaultorder,
                tskt.col_id;
  
    --get resolution codes for the task
    OPEN :CUR_RESCODES FOR
      SELECT rc.col_id          AS ID,
             rc.col_code        AS CODE,
             rc.col_description AS DESCRIPTION,
             rc.col_name        AS NAME,
             rc.col_iconcode    AS ICONCODE,
             rc.col_theme       AS THEME
        FROM tbl_task t
       INNER JOIN tbl_tasksystyperesolutioncode m
          ON m.col_tbl_dict_tasksystype = t.col_taskdict_tasksystype
       INNER JOIN tbl_stp_resolutioncode rc
          ON rc.col_id = m.col_tbl_stp_resolutioncode
       WHERE t.col_id = v_task_id
       ORDER BY UPPER(rc.col_name);
  
    -- GET COUNTERS DATA
    v_result      := f_DCM_getObjectCountsFn(CaseId => NULL, TaskId => v_task_id, ExternalPartyId => NULL, ITEMS => v_Counters);
    :CUR_COUNTERS := v_Counters;
  
  END IF;

END;
