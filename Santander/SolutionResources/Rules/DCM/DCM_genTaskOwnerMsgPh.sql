DECLARE 
    --input/output
	v_taskid INTEGER; 	

	--internal
	v_inCache INTEGER;
  v_CSisInCache INTEGER;
  
BEGIN 
    v_taskid := :TaskId; --because of legacy 
	  v_inCache := f_DCM_isTaskInCache(TaskID => v_taskid);
    v_CSisInCache :=f_DCM_CSisTaskInCache(TaskID => v_taskid);
	
	--get case from proper place
	IF v_inCache = 1 THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   tbl_taskCC tse 
    inner join vw_PPL_SimpleWorkBasket wb ON tse.COL_TASKCCPPL_WORKBASKET = wb.id
		WHERE  tse.col_id = v_taskid; 	
  END IF;  
    
  IF (v_inCache = 0) AND (v_CSisInCache=0) THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   tbl_task tse 
		inner join vw_PPL_SimpleWorkBasket wb ON tse.COL_TASKPPL_WORKBASKET = wb.id
		WHERE  tse.col_id = v_taskid;
	END IF;
  
  IF v_CSisInCache=1 THEN
		SELECT wb.CALCNAME || '(' || wb.CALCTYPE || ')'
		INTO   :PlaceholderResult 
		FROM   tbl_Cstask tse 
		inner join vw_PPL_SimpleWorkBasket wb ON tse.COL_TASKPPL_WORKBASKET = wb.id
		WHERE  tse.col_id = v_taskid;
	END IF;  
	
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';

EXCEPTION 
	WHEN no_data_found THEN 
		:PlaceholderResult := 'NONE'; 
	WHEN OTHERS THEN 
		:PlaceholderResult := 'SYSTEM ERROR'; 
END;