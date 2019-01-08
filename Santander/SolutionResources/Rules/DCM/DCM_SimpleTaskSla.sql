SELECT    tsk.col_id AS ID,
          tsk.col_name AS TASKNAME,
          tsk.col_taskid AS TASKID,
          tsk.col_taskorder AS TaskOrder,
          tsk.col_casetask AS CASEID,
          tsk.col_parentid AS PARENTID,
          tsk.col_createdby AS CreatedBy,
          tsk.col_createddate AS CreatedDate,
          tsk.col_modifiedby AS ModifiedBy,
          tsk.col_modifieddate AS ModifiedDate,
			 tsk.col_duedate as DueDate,
          tsk.col_taskdict_tasksystype AS TaskSysType,
          dts.col_id AS TASKSTATE_ID,
          dts.col_name AS TASKSTATE_NAME,
          dts.col_isdefaultoncreate AS TASKSTATE_ISDEFAULTONCREATE,
          dts.col_isstart AS TASKSTATE_ISSTART,
          dts.col_isresolve AS TASKSTATE_ISRESOLVE,
          dts.col_isfinish AS TASKSTATE_ISFINISH,
          tsk.col_taskstp_resolutioncode AS ResolutionCode_Id,
          rt.col_name AS ResolutionCode_Name,
          rt.col_code AS ResolutionCode_Code,
          rt.col_iconcode AS ResolutionCode_Icon,
          rt.col_theme AS ResolutionCode_Theme,
          wb.col_id AS WORKBASKET_ID,
          wb.col_code AS WORKBASKET_CODE,
          wb.col_name AS WORKBASKET_NAME,
          wbt.col_code AS Workbasket_type_code,
          cast(tsk.col_goalslaeventdate as timestamp) as GoalSlaDateTime,
          cast(tsk.col_dlineslaeventdate as timestamp) as DLineSlaDateTime,
          tst.col_iconCode AS CALC_ICON,
          tst.col_name AS TaskType_Name,
          tsk.COL_ISHIDDEN AS IsHidden  			 
FROM      tbl_task tsk
LEFT JOIN tbl_dict_taskstate dts   ON tsk.col_taskdict_taskstate = dts.col_id
LEFT JOIN tbl_ppl_workbasket wb    ON tsk.col_taskppl_workbasket = wb.col_id
LEFT JOIN tbl_dict_workbaskettype    wbt ON wbt.col_id = wb.col_workbasketworkbaskettype
LEFT JOIN tbl_dict_tasksystype tst ON tsk.col_taskdict_tasksystype = tst.col_id
LEFT JOIN tbl_stp_resolutioncode rt ON tsk.col_taskstp_resolutioncode = rt.col_id