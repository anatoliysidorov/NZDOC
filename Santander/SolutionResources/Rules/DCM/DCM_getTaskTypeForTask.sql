DECLARE
    v_tasktypeid INTEGER;
BEGIN
    BEGIN
        SELECT COL_TASKDICT_TASKSYSTYPE
        INTO v_tasktypeid
        FROM tbl_task
        WHERE col_id = :TaskId;
    
    EXCEPTION
    WHEN no_data_found THEN
        v_tasktypeid := NULL;
    END;
    
    RETURN v_tasktypeid;
END;