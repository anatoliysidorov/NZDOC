BEGIN
  DECLARE
     v_WorkItemId NUMBER;
     v_InstanceId NVARCHAR2(255);
     v_WorkflowCode NVARCHAR2(255);
     v_ActivityCode NVARCHAR2(255);
     v_AccessSubjectCode NVARCHAR2(255);
  BEGIN	
     v_InstanceId := sys_guid();
     v_WorkflowCode := :WorkflowCode;
     v_ActivityCode := :ActivityCode;
     v_AccessSubjectCode := :AccessSubjectCode;

     INSERT INTO tbl_CW_Workitem (
       COL_WORKFLOW,
       COL_ACTIVITY,
       col_cw_workitemdict_casestate,
       COL_INSTANCEID,
       COL_OWNER,
       COL_CREATEDBY,
       COL_CREATEDDATE,
       COL_INSTANCETYPE
     )
     VALUES (
       v_WorkflowCode,
       v_ActivityCode,
       (select col_id from tbl_dict_casestate where col_activity = v_ActivityCode),
       v_InstanceId,
       v_AccessSubjectCode,
       :TOKEN_USERACCESSSUBJECT,
       sysdate,
       1
     );
     

     :ErrorCode := 0;
     :ErrorMessage := '';

     SELECT gen_tbl_CW_Workitem.currval INTO v_WorkItemId FROM DUAL;

     update tbl_case
     set col_cw_workitemcase = v_WorkItemId,
     col_activity = v_ActivityCode,
     col_workflow = v_WorkflowCode,
     col_casedict_casestate = (select col_id from tbl_dict_casestate where col_activity = v_ActivityCode)
     where col_id = :CaseId;

EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
          :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;