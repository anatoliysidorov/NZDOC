BEGIN
  DECLARE
     v_WorkItemId NUMBER;

     v_InstanceId NVARCHAR2(255);
     v_ParentInstanceId NVARCHAR2(255);
     v_WorkflowCode NVARCHAR2(255);
     v_ActivityCode NVARCHAR2(255);
     v_AccessSubjectCode NVARCHAR2(255);

  BEGIN	
          :ErrorCode := 0;
          :ErrorMessage := '';

          v_InstanceId := :InstanceId;
          v_ParentInstanceId := :ParentInstanceId;
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
                COL_REFPARENTID,
                COL_INSTANCETYPE
          )
          SELECT v_WorkflowCode, v_ActivityCode, v_InstanceId, v_AccessSubjectCode, '@TOKEN_USERACCESSSUBJECT@', sysdate, w.COL_ID, 1
          FROM TBL_CW_WORKITEM w
          WHERE w.COL_INSTANCEID = v_ParentInstanceId;

	  SELECT gen_tbl_CW_Workitem.currval INTO v_WorkItemId FROM DUAL;

          UPDATE TBL_CW_WORKITEM SET COL_INSTANCETYPE = 2 WHERE COL_INSTANCEID = v_ParentInstanceId;
  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
              :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;