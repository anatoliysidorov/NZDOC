DECLARE
  v_ProcedureId  NUMBER;
  v_SourceTaskId NUMBER;
  v_TargetTaskId NUMBER;
  v_srcid        NUMBER;
  v_srcname      NVARCHAR2(255);
  v_srctaskid    NVARCHAR2(255);
  v_srcdepth     NUMBER;
  v_srctaskorder NUMBER;
  v_srcparentid  NUMBER;
  v_trgid        NUMBER;
  v_trgname      NVARCHAR2(255);
  v_trgtaskid    NVARCHAR2(255);
  v_trgdepth     NUMBER;
  v_trgtaskorder NUMBER;
  v_trgparentid  NUMBER;
  v_Position     NVARCHAR2(32);
  v_NewParentId  NUMBER;
  v_NewTaskOrder NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_errorcode    := 0;
  v_errormessage := '';

  v_ProcedureId  := :ProcedureId;
  v_SourceTaskId := :SourceTaskId;
  v_TargetTaskId := :TargetTaskId;
  v_Position     := :Position; -- "before", "after" or "append"

  BEGIN
    BEGIN
    
      SELECT col_id,
             col_name,
             col_taskid,
             col_depth,
             col_taskorder,
             col_parentttid
        INTO v_srcid,
             v_srcname,
             v_srctaskid,
             v_srcdepth,
             v_srctaskorder,
             v_srcparentid
        FROM tbl_tasktemplate
       WHERE col_id = v_SourceTaskId
         AND col_proceduretasktemplate = v_ProcedureId;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 101;
        v_errormessage := 'Record with source id ' || to_char(v_SourceTaskid) || ' is not found: operation is not allowed';
        GOTO cleanup;
    END;
  
    BEGIN
    
      SELECT col_id,
             col_name,
             col_taskid,
             col_depth,
             col_taskorder,
             col_parentttid
        INTO v_trgid,
             v_trgname,
             v_trgtaskid,
             v_trgdepth,
             v_trgtaskorder,
             v_trgparentid
        FROM tbl_tasktemplate
       WHERE col_id = v_TargetTaskId
         AND col_proceduretasktemplate = v_ProcedureId;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 102;
        v_errormessage := 'Record with target id ' || to_char(v_TargetTaskid) || ' is not found: operation is not allowed';
        GOTO cleanup;
    END;
  
    v_NewParentId  := v_trgparentid;
    v_NewTaskOrder := v_trgtaskorder;
    IF (v_Position = 'append') THEN
      v_NewParentId := v_TargetTaskId;
      SELECT NVL(MAX(col_taskorder), 0) + 1
        INTO v_NewTaskOrder
        FROM tbl_tasktemplate
       WHERE col_parentttid = v_TargetTaskId
         AND col_proceduretasktemplate = v_ProcedureId;
    END IF;
    IF (v_Position = 'after') THEN
      v_NewTaskOrder := v_trgtaskorder + 1;
    
      FOR i IN (SELECT col_id
                  FROM tbl_tasktemplate
                 WHERE col_parentttid = v_trgparentid
                   AND col_proceduretasktemplate = v_ProcedureId
                   AND col_taskorder >= v_NewTaskOrder) LOOP
        UPDATE tbl_tasktemplate SET col_taskorder = col_taskorder + 1 WHERE col_id = i.col_id;
      END LOOP;
    
    END IF;
  
    IF (v_Position = 'before') THEN
      v_NewTaskOrder := v_trgtaskorder;
    
      FOR i IN (SELECT col_id
                  FROM tbl_tasktemplate
                 WHERE col_parentttid = v_trgparentid
                   AND col_proceduretasktemplate = v_ProcedureId
                   AND col_taskorder >= v_NewTaskOrder) LOOP
        UPDATE tbl_tasktemplate SET col_taskorder = col_taskorder + 1 WHERE col_id = i.col_id;
      END LOOP;
    END IF;
  
    UPDATE tbl_tasktemplate
       SET col_taskorder = v_NewTaskOrder, col_parentttid = v_NewParentId, col_depth = v_trgdepth
     WHERE col_id = v_SourceTaskId
       AND col_proceduretasktemplate = v_ProcedureId;
  
    UPDATE tbl_tasktemplate
       SET col_depth = col_depth - v_srcdepth + v_trgdepth
     WHERE col_id IN (SELECT col_id
                        FROM tbl_tasktemplate
                       WHERE col_proceduretasktemplate = v_ProcedureId
                         AND col_id <> v_SourceTaskId
                       START WITH col_id = v_SourceTaskId
                      CONNECT BY PRIOR col_id = col_parentttid);
  
    FOR i IN (SELECT col_id,
                     rownum rn
                FROM (SELECT col_id,
                             col_taskorder
                        FROM tbl_tasktemplate
                       WHERE col_parentttid = v_trgparentid
                         AND col_proceduretasktemplate = v_ProcedureId
                       ORDER BY col_taskorder)) LOOP
      UPDATE tbl_tasktemplate SET col_taskorder = i.rn WHERE col_id = i.col_id;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 100;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;
  
  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;
END;