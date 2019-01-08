BEGIN
  BEGIN	
      :ErrorCode := 0;
      :ErrorMessage := '';
 	  :InstanceId := '';
	  :WorkflowCode := '';  
  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
          :ErrorMessage := SUBSTR(SQLERRM, 1, 200); 	     
  END;
END;