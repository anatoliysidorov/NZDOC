DECLARE
  v_InstanceId NVARCHAR2(255);
  v_WorkflowCode NVARCHAR2(255);
  v_ActivityCode NVARCHAR2(255);
  v_AccessSubjectCode NVARCHAR2(255);

  v_Activity NVARCHAR2(255);
BEGIN
  BEGIN
    v_InstanceId := :InstanceId;
    v_WorkflowCode := :WorkflowCode;
    v_ActivityCode := :ActivityCode;
    v_AccessSubjectCode := :AccessSubjectCode;
	
    SELECT COL_ACTIVITY
        INTO v_Activity	
        FROM TBL_CW_WORKITEM WHERE COL_INSTANCEID = v_InstanceId;

        UPDATE TBL_CW_WORKITEM 
		SET COL_WORKFLOW = v_WorkflowCode,
		COL_ACTIVITY = v_ActivityCode,
		COL_OWNER = v_AccessSubjectCode,
		COL_MODIFIEDBY = '@TOKEN_USERACCESSSUBJECT@',
		COL_MODIFIEDDATE = sysdate,
                COL_PREVACTIVITY = v_Activity
	WHERE COL_INSTANCEID = v_InstanceId;

        :ErrorCode := 0;
        :ErrorMessage := '';
   EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
              :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
   END;
END;