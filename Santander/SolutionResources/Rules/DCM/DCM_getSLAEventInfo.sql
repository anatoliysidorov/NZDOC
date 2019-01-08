DECLARE 
  --INTERNAL 
  v_count  INTEGER; 
  v_taskid INTEGER; 
  v_caseid INTEGER; 
BEGIN 
  --DETERMINE IF SLA EVENT IS IN CACHE 
  :IsInCache := f_DCM_isSLAinCache(:SLAEventID);
  
  --GET CONTEXT 
  IF :IsInCache = 1 THEN 
    SELECT col_slaeventcctaskcc, 
           col_slaeventcccasecc 
    INTO   v_taskid, 
           v_caseid 
    FROM   tbl_slaeventcc 
    WHERE  col_id = :SLAEventID; 
   
  ELSE 
    SELECT col_slaeventtask, 
           col_slaeventcase 
    INTO   v_taskid, 
           v_caseid 
    FROM   tbl_slaevent 
    WHERE  col_id = :SLAEventID;    
  END IF; 
  
  IF NVL(v_taskid, 0) > 0 THEN 
    :TargetId := v_taskid; 
    :TargetType := 'TASK'; 
  ELSIF NVL(v_caseid, 0) > 0 THEN
	:TargetId := v_caseid; 
    :TargetType := 'CASE'; 
  ELSE 
    :TargetId := NULL; 
    :TargetType := NULL; 
  END IF; 
  
EXCEPTION  
WHEN OTHERS THEN 
  :TargetId := NULL; 
  :TargetType := NULL; 
END;