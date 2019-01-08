BEGIN
  DECLARE
     v_WorkItemId number;
     v_InstanceId nvarchar2(255);
     v_WorkflowCode nvarchar2(255);
     v_ActivityCode nvarchar2(255);
     v_AccessSubjectCode nvarchar2(255);
     v_Owner nvarchar2(255);
     v_TaskId Integer;
     v_result nvarchar2(255);
  BEGIN	
     v_InstanceId := sys_guid();
     v_WorkflowCode := :WorkflowCode;
     v_ActivityCode := :ActivityCode;
     v_AccessSubjectCode := :AccessSubjectCode;
     v_Owner := :Owner;
     v_TaskId := :TaskId;

     begin
       select ts.col_activity into v_result
       from tbl_taskcc tsk
       inner join tbl_tasktemplate tt on tsk.col_id2 = tt.col_id
       left join tbl_dict_taskstate ts on tt.col_tasktmpldict_taskstate = ts.col_id
       where tsk.col_id = v_TaskId;
       exception
       when NO_DATA_FOUND then
       v_result := null;
     end;
     
     if v_result is not null then
      v_ActivityCode := v_result;
     end if;


     INSERT INTO tbl_TW_WorkitemCC (
       COL_WORKFLOW,
       COL_ACTIVITY,
       COL_TW_WORKITEMCCDICT_TASKST,
       COL_INSTANCEID,
       COL_OWNER,
       COL_CREATEDBY,
       COL_CREATEDDATE,
       COL_INSTANCETYPE
     )
     VALUES (
       v_WorkflowCode,
       v_ActivityCode,
       (select col_id
       from tbl_dict_taskstate
       where col_activity = v_ActivityCode
       and nvl(col_stateconfigtaskstate,0) =
           case when (select col_taskccdict_tasksystype from tbl_taskcc where col_id = TaskId) is null then
             case when (select col_id from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task') is not null then
                       (select col_id from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task')
                  else
                       0
                  end
           else
             (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = TaskId))
           end),
       v_InstanceId,
       v_Owner,
       TOKEN_USERACCESSSUBJECT,
       sysdate,
       1
     );

     ErrorCode := 0;
     ErrorMessage := '';

     SELECT gen_tbl_TW_WorkitemCC.currval INTO v_WorkItemId FROM DUAL;

     update tbl_taskcc
     set col_tw_workitemcctaskcc = v_WorkItemId
     where col_id = TaskId;

  EXCEPTION
          WHEN OTHERS THEN
          ErrorCode := 100;
          ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END; 