DECLARE
  v_InstanceId NVARCHAR2(255);
  v_WorkflowCode NVARCHAR2(255);
BEGIN
  BEGIN	
      :ErrorCode := 0;
      :ErrorMessage := '';
      v_InstanceId := :InstanceId;
      v_WorkflowCode := :WorkflowCode;
  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
              :ErrorMessage := SUBSTR(SQLERRM, 1, 200); 	     
  END;
END;