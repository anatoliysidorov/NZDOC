SELECT tskt.col_id         AS ID, 
       tskt.col_name       AS TransitionName, 
       tskt.col_iconcode   AS TransitionIconCode, 
       tskts.col_activity  AS NextActivity, 
       tskts.col_code      AS NextActivity_Code, 
       tskts.col_isstart   AS NextActivity_IsStart, 
       tskts.col_isfinish  AS NextActivity_IsFinish, 
       tskts.col_isresolve AS NextActivity_IsResolve, 
	   tskts.col_canassign AS NextActivity_CanAssign, 
       dim.col_code        AS TaskNextStateInitMethod 
FROM   tbl_dict_tasktransition tskt 
       inner join tbl_dict_taskstate tskss 
               ON tskt.col_sourcetasktranstaskstate = tskss.col_id 
       inner join tbl_dict_taskstate tskts 
               ON tskt.col_targettasktranstaskstate = tskts.col_id 
       inner join tbl_tw_workitem twi 
               ON tskss.col_id = twi.col_tw_workitemdict_taskstate 
       inner join tbl_task tsk 
               ON twi.col_id = tsk.col_tw_workitemtask 
       inner join tbl_case cs 
               ON tsk.col_casetask = cs.col_id 
       inner join tbl_map_taskstateinitiation mtsi 
               ON tsk.col_id = mtsi.col_map_taskstateinittask 
                  AND tskts.col_id = mtsi.col_map_tskstinit_tskst 
       inner join tbl_dict_initmethod dim 
               ON mtsi.col_map_tskstinit_initmtd = dim.col_id 
       left join tbl_fom_uielement uecttt 
              ON tskt.col_id = uecttt.col_uielementtasktransition 
                 AND cs.col_casedict_casesystype = 
                     uecttt.col_uielementcasesystype 
                 AND tsk.col_taskdict_tasksystype = 
                     uecttt.col_uielementtasksystype 
       left join tbl_fom_uielement uett 
              ON tskt.col_id = uett.col_uielementtasktransition 
                 AND uett.col_uielementcasesystype IS NULL 
                 AND tsk.col_taskdict_tasksystype = 
                     uett.col_uielementtasksystype 
       left join tbl_fom_uielement ue 
              ON tskt.col_id = ue.col_uielementtasktransition 
                 AND ue.col_uielementcasesystype IS NULL 
                 AND ue.col_uielementtasksystype IS NULL 
WHERE  CASE 
         WHEN uecttt.col_id IS NOT NULL THEN Nvl(uecttt.col_ishidden, 0) 
         WHEN uett.col_id IS NOT NULL THEN Nvl(uett.col_ishidden, 0) 
         WHEN ue.col_id IS NOT NULL THEN Nvl(ue.col_ishidden, 0) 
         ELSE 0 
       END = 0 
       AND tsk.col_id = :TaskId 