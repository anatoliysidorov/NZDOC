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

     INSERT INTO tbl_TW_Workitem (
       COL_WORKFLOW,
       COL_ACTIVITY,
       col_tw_workitemdict_taskstate,
       COL_INSTANCEID,
       COL_OWNER,
       COL_CREATEDBY,
       COL_CREATEDDATE,
       COL_INSTANCETYPE
     )
     VALUES (
       v_WorkflowCode,
       v_ActivityCode,
       (select col_id from tbl_dict_taskstate where col_activity = v_ActivityCode),
       v_InstanceId,
       v_Owner,
       :TOKEN_USERACCESSSUBJECT,
       sysdate,
       1
     );

     :ErrorCode := 0;
     :ErrorMessage := '';

     SELECT gen_tbl_TW_Workitem.currval INTO v_WorkItemId FROM DUAL;
     
     update tbl_dynamictask
     set col_dynamictasktw_workitem = v_WorkItemId
     where col_id = :TaskId;

  EXCEPTION
    WHEN OTHERS THEN
      :ErrorCode := 100;
      :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;