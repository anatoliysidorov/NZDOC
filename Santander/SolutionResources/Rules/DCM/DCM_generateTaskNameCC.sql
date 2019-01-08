DECLARE 
    v_taskid INTEGER; 
BEGIN 
    v_taskid := :TaskId; 

    UPDATE tbl_taskcc 
    SET    col_name = Nvl(col_name, 'Task') || '-' || To_char(col_id) 
    WHERE  col_id = v_taskid; 
END; 