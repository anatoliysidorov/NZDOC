DECLARE
	--input
	v_task_id integer;

BEGIN
	--input
	v_task_id := :Task_Id;
	
	--system
	:ErrorCode := 0;
	:ErrorMessage := '';
	
	--get next states for the task
	OPEN :CUR_AVAILTRANSITIONS FOR
        SELECT tskt.col_id         AS ID,
               tskt.col_name       AS NAME,
               tskt.col_iconcode   AS ICONCODE,
               tskts.col_activity  AS TARGET_ACTIVITY,
               tskts.col_isstart   AS TARGET_ISSTART,
               tskts.col_isfinish  AS TARGET_ISFINISH,
               tskts.col_isresolve AS TARGET_ISRESOLVE,
               tskts.col_canassign AS TARGET_CANASSIGN
        FROM   tbl_dict_tasktransition tskt
        left join tbl_dict_taskstate tskss ON tskt.col_sourcetasktranstaskstate = tskss.col_id
        left join tbl_dict_taskstate tskts ON tskt.col_targettasktranstaskstate = tskts.col_id
        left join tbl_tw_workitem twi ON tskss.col_id = twi.col_tw_workitemdict_taskstate
        left join tbl_task tsk ON twi.col_id = tsk.col_tw_workitemtask
        left join tbl_case cs ON tsk.col_casetask = cs.col_id 
        left join tbl_map_taskstateinitiation mtsi ON tsk.col_id = mtsi.col_map_taskstateinittask AND tskts.col_id = mtsi.col_map_tskstinit_tskst
        left join tbl_dict_initmethod dim ON mtsi.col_map_tskstinit_initmtd = dim.col_id
        left join tbl_fom_uielement uecttt ON tskt.col_id = uecttt.col_uielementtasktransition AND cs.col_casedict_casesystype = uecttt.col_uielementcasesystype AND tsk.col_taskdict_tasksystype = uecttt.col_uielementtasksystype
        left join tbl_fom_uielement uett ON tskt.col_id = uett.col_uielementtasktransition AND uett.col_uielementcasesystype IS NULL AND tsk.col_taskdict_tasksystype = uett.col_uielementtasksystype
        left join tbl_fom_uielement ue ON tskt.col_id = ue.col_uielementtasktransition AND ue.col_uielementcasesystype IS NULL AND ue.col_uielementtasksystype IS NULL
        WHERE  CASE 
               WHEN uecttt.col_id IS NOT NULL THEN Nvl(uecttt.col_ishidden, 0)
               WHEN uett.col_id IS NOT NULL THEN Nvl(uett.col_ishidden, 0)
               WHEN ue.col_id IS NOT NULL THEN Nvl(ue.col_ishidden, 0)
               ELSE 0
               END = 0
        --AND lower(dim.col_code) in ('manual', 'automatic')
        AND tsk.col_id = v_task_id
        ORDER BY tskss.col_defaultorder, tskt.col_id;
	
	--get resolution codes for the task
	OPEN :CUR_RESCODES FOR
		SELECT 
			rc.col_id as ID,
			rc.col_code as CODE,
			rc.col_description as DESCRIPTION,
			rc.col_name as NAME,
			rc.col_iconcode as ICONCODE,
			rc.col_theme as THEME
		FROM tbl_task t
		INNER JOIN tbl_tasksystyperesolutioncode m ON m.col_tbl_dict_tasksystype = t.col_taskdict_tasksystype
		INNER JOIN tbl_stp_resolutioncode rc ON rc.col_id = m.col_tbl_stp_resolutioncode
		WHERE t.col_id = v_task_id
		ORDER BY UPPER(rc.col_name);
END;