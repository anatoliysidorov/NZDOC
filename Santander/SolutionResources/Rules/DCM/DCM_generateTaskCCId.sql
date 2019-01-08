DECLARE 
    v_taskid                INTEGER; 
    v_tasktitle             NVARCHAR2(255); 
    v_tasktypeid            INTEGER; 
    v_tasktypecode          NVARCHAR2(255); 
    v_tasktypename          NVARCHAR2(255); 
    v_tasktypeprocessorcode NVARCHAR2(255); 
    v_stateconfigid         INTEGER; 
    v_errorcode             NUMBER; 
    v_errormessage          NVARCHAR2(255); 
    v_affectedrows          NUMBER; 
    v_result                NUMBER; 
BEGIN 
    v_taskid := :TaskId; 

    BEGIN 
        SELECT tsk.col_taskccdict_tasksystype 
        INTO   v_tasktypeid 
        FROM   tbl_taskcc tsk 
        WHERE  tsk.col_id = v_taskid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_tasktypeid := NULL; 
          v_errorcode := 101; 
          v_errormessage := 'Task type for task ' || To_char(v_taskid) || ' not found'; 
          RETURN -1; 
    END; 

    BEGIN 
        SELECT col_code, 
               col_name, 
               col_processorcode, 
               col_stateconfigtasksystype 
        INTO   v_tasktypecode, v_tasktypename, v_tasktypeprocessorcode, 
               v_stateconfigid 
        FROM   tbl_dict_tasksystype 
        WHERE  col_id = v_tasktypeid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_errorcode := 102; 
          v_errormessage := 'Task type not found'; 
          RETURN -1; 
    END; 

    --GENERATE TASK TITLE 
    IF v_tasktypeprocessorcode IS NOT NULL THEN 
      v_tasktitle := F_dcm_invoketaskidgenproc( processorname => v_tasktypeprocessorcode, taskid => v_taskid); 

      UPDATE tbl_taskcc 
      SET    col_taskid = v_tasktitle 
      WHERE  col_id = v_taskid; 
    ELSE 
      v_result := F_dcm_generatetaskccid2(
		affectedrows => v_affectedrows,
		errorcode => errorcode, 
		errormessage => errormessage, 
		prefix => 'TASK', 
		recordid => v_taskid, 
		taskid => v_tasktitle
	); 
    END IF; 

    :TaskTitle := v_tasktitle; 
END; 