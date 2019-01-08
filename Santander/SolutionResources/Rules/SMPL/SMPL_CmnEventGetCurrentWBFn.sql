DECLARE
  v_taskId            NUMBER;  
   
BEGIN

  --INPUT
  v_taskId :=:TargetId;--fake, only for invoker
  :Result := NULL;
    
  :Result:= TO_CHAR(f_DCM_getMyPersonalWorkbasket()); 
    
END;