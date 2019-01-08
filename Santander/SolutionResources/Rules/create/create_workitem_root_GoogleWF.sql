BEGIN
  DECLARE
     v_WorkItemId NUMBER;
     v_InstanceId NVARCHAR2(255);
     v_WorkflowCode NVARCHAR2(255);
     v_ActivityCode NVARCHAR2(255);
     v_AccessSubjectCode NVARCHAR2(255);
  BEGIN	
     v_InstanceId := :InstanceId;
     v_WorkflowCode := :WorkflowCode;
     v_ActivityCode := :ActivityCode;
     v_AccessSubjectCode := :AccessSubjectCode;

     INSERT INTO TBL_CW_WORKITEM (
   	COL_WORKFLOW,
   	COL_ACTIVITY,
   	COL_INSTANCEID,
   	COL_OWNER,
   	COL_CREATEDBY,
        COL_CREATEDDATE,
        COL_INSTANCETYPE
     )
     VALUES (
       v_WorkflowCode,
       v_ActivityCode,
       v_InstanceId,
       v_AccessSubjectCode,
       '@TOKEN_USERACCESSSUBJECT@',
       sysdate,
       1
     );

     :ErrorCode := 0;
     :ErrorMessage := '';

     SELECT gen_tbl_CW_Workitem.currval INTO v_WorkItemId FROM DUAL;
  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
              :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;