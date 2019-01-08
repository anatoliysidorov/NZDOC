BEGIN
  DECLARE
     v_WorkItemId NUMBER;
     v_InstanceId NVARCHAR2(255);
     v_WorkflowCode NVARCHAR2(255);
     v_ActivityCode NVARCHAR2(255);
     v_AccessSubjectCode NVARCHAR2(255);
     v_Owner NVARCHAR2(255);
  BEGIN	
     v_InstanceId := sys_guid();
     v_WorkflowCode := :WorkflowCode;
     v_ActivityCode := :ActivityCode;
     v_AccessSubjectCode := :AccessSubjectCode;
     v_Owner := :Owner;

     INSERT INTO tbl_TW_Workitemcc (
       COL_WORKFLOW,
       COL_ACTIVITY,
       col_tw_workitemccdict_taskst,
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
           case when (select col_taskccdict_tasksystype from tbl_taskcc where col_id = :TaskId) is null then
             case when (select col_id from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task') is not null then
                       (select col_id from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task')
                  else
                       0
                  end
           else
             (select nvl(col_stateconfigtasksystype,0) from tbl_dict_tasksystype where col_id = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = :TaskId))
           end),
       v_InstanceId,
       v_Owner,
       :TOKEN_USERACCESSSUBJECT,
       sysdate,
       1
     )  RETURNING col_id INTO v_WorkItemId;

     :ErrorCode := 0;
     :ErrorMessage := '';
     
     update tbl_taskcc
     set col_tw_workitemcctaskcc = v_WorkItemId
     where col_id = :TaskId;

  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
          :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;