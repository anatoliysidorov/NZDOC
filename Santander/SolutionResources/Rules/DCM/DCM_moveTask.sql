BEGIN
  DECLARE
        v_CaseId NUMBER;
        v_SourceTaskId NUMBER;
        v_TargetTaskId NUMBER;
        v_srcid NUMBER;
        v_srcname nvarchar2(255);
        v_srctaskid nvarchar2(255);
        v_srcdepth number;
        v_srctaskorder number;
        v_srcparentid number;
        v_trgid number;
        v_trgname nvarchar2(255);
        v_trgtaskid nvarchar2(255);
        v_trgdepth number;
        v_trgtaskorder number;
        v_trgparentid number;
        v_Position nvarchar2(32);
		
		v_NewParentId number;
		v_NewTaskOrder number;
  BEGIN	
      :ErrorCode := 0;
      :ErrorMessage := '';
      
      v_CaseId := :CaseId;
      v_SourceTaskId := :SourceTaskId;
      v_TargetTaskId := :TargetTaskId;
	  v_Position := :Position; -- "before", "after" or "append"
      
    BEGIN
      
      select col_id, col_name, col_taskid, col_depth, col_taskorder, col_parentid 
      into v_srcid, v_srcname, v_srctaskid, v_srcdepth, v_srctaskorder, v_srcparentid
      from tbl_task where col_id = v_SourceTaskId and col_casetask = v_CaseId;
      
      EXCEPTION
      WHEN NO_DATA_FOUND then
         :ErrorCode := 101;
         :ErrorMessage := 'Record with source id ' || to_char(v_SourceTaskid) || ' is not found: operation is not allowed';
         goto Cleanup;
    END;
        
    BEGIN
      
      select col_id, col_name, col_taskid, col_depth, col_taskorder, col_parentid
      into v_trgid, v_trgname, v_trgtaskid, v_trgdepth, v_trgtaskorder, v_trgparentid
      from tbl_task where col_id = v_TargetTaskId and col_casetask = v_CaseId;
      
      EXCEPTION
      WHEN NO_DATA_FOUND then
         :ErrorCode := 101;
         :ErrorMessage := 'Record with target id ' || to_char(v_TargetTaskid) || ' is not found: operation is not allowed';
         goto Cleanup;
    END;
	
	v_NewParentId := v_trgparentid;
	v_NewTaskOrder := v_trgtaskorder;
	IF (v_Position = 'append') THEN
		v_NewParentId := v_TargetTaskId;
		SELECT MAX(col_taskorder)+1 INTO v_NewTaskOrder FROM tbl_task WHERE col_parentid = v_TargetTaskId AND col_casetask = v_CaseId;
	END IF;
    IF (v_Position = 'after') THEN
		v_NewTaskOrder := v_trgtaskorder+1;
		/*UPDATE tbl_task
		SET col_taskorder = col_taskorder+1
		WHERE col_parentid = v_TargetTaskId AND col_casetask = v_CaseId AND col_taskorder >= v_NewTaskOrder;*/

FOR i IN (SELECT col_id FROM tbl_task
               WHERE col_parentid = v_trgparentid AND col_casetask = v_CaseId AND col_taskorder >= v_NewTaskOrder) 
    LOOP
      UPDATE tbl_task
          SET col_taskorder = col_taskorder+1
        WHERE col_id = i.col_id;        
    END LOOP;

	END IF;

IF (v_Position = 'before') THEN
	  v_NewTaskOrder := v_trgtaskorder;
		
    FOR i IN (SELECT col_id FROM tbl_task
               WHERE col_parentid = v_trgparentid AND col_casetask = v_CaseId AND col_taskorder >= v_NewTaskOrder) 
    LOOP
      UPDATE tbl_task
          SET col_taskorder = col_taskorder+1
        WHERE col_id = i.col_id;        
    END LOOP;
	END IF;
	  
      
      UPDATE tbl_task SET col_taskorder = v_NewTaskOrder,
      col_parentid = v_NewParentId, col_depth = v_trgdepth
      WHERE col_id = v_SourceTaskId AND col_casetask = v_CaseId;
      --:ErrorMessage := 'v_trgparentid='||v_trgparentid||'v_SourceTaskId='||v_SourceTaskId;

      UPDATE tbl_task SET col_depth = col_depth - v_srcdepth + v_trgdepth
      WHERE col_id IN
        (SELECT col_id
        FROM tbl_task
        WHERE col_casetask = v_CaseId AND col_id <> v_SourceTaskId
        START WITH col_id = v_SourceTaskId
        CONNECT BY PRIOR col_id = col_parentid);
      
    FOR i IN (SELECT col_id, rownum rn 
                FROM (SELECT col_id, col_taskorder
                        FROM tbl_task
                       WHERE col_parentid = v_trgparentid AND col_casetask = v_CaseId
                    ORDER BY col_taskorder)
             )
    LOOP
      UPDATE tbl_task
          SET col_taskorder = i.rn
        WHERE col_id = i.col_id;        
    END LOOP;

      EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
          :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
      END;
	  <<Cleanup>> :ErrorCode := :ErrorCode;
    END;
