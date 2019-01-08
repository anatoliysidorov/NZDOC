DECLARE 
    v_taskid             INTEGER; 
    v_processorcode      NVARCHAR2(255); 
    v_initmethodid       INTEGER; 
    v_taskstatenew       NVARCHAR2(255); 
    v_count              INTEGER; 
    v_tasksystypeid      INTEGER; 
    v_counter            NUMBER; 
    v_lastcounter        NUMBER; 
    v_result INTEGER;
BEGIN 
    v_taskid := :TaskId; 
    v_processorcode := NULL; 
    v_taskstatenew := 'new'; 
	
	--GET MANUAL INIT METHOD
	v_initmethodid := f_UTIL_getIdByCode(TableName => 'tbl_dict_initmethod', Code => 'manual');

	--GET TASK TYPE OF TASK
    BEGIN 
        SELECT col_taskccdict_tasksystype 
        INTO   v_tasksystypeid 
        FROM   tbl_taskcc       
        WHERE  col_id = v_taskid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_tasksystypeid := NULL; 
    END; 


    v_result := f_UTIL_createSysLogFn('asdasdsad'); 

    BEGIN 
        SELECT Count(*) 
        INTO   v_count 
        FROM   tbl_MAP_TaskStateInitiation 
        WHERE  COL_TASKSTATEINIT_TASKSYSTYPE = v_tasksystypeid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_count := 0; 
    END; 
    
    v_result := f_UTIL_createSysLogFn(TO_CHAR(v_taskid));
    
    IF v_count > 0 THEN 
      SELECT gen_tbl_map_taskstateinitcc.NEXTVAL 
      INTO   v_counter 
      FROM   dual; 

      INSERT INTO tbl_map_taskstateinitcc 
                  (col_map_taskstateinitcctaskcc, 
                   col_map_tskstinitcc_initmtd, 
                   col_map_tskstinitcc_tskst, 
                   col_processorcode, 
                   col_assignprocessorcode) 
      (SELECT v_taskid, 
              COL_MAP_TSKSTINIT_INITMTD, 
              COL_MAP_TSKSTINIT_TSKST, 
              COL_PROCESSORCODE, 
              COL_ASSIGNPROCESSORCODE 
       FROM   tbl_MAP_TaskStateInitiation 
       WHERE  COL_TASKSTATEINIT_TASKSYSTYPE = v_tasksystypeid); 
       
       select gen_tbl_map_taskstateinitcc.currval into v_lastcounter from dual;

      FOR rec IN (SELECT col_id 
                  FROM   tbl_map_taskstateinitcc 
                  WHERE  col_id BETWEEN v_counter AND v_lastcounter) LOOP 
          UPDATE tbl_map_taskstateinitcc 
          SET    col_code = Sys_guid() 
          WHERE  col_id = rec.col_id; 
      END LOOP; 
    ELSE 
      FOR cur IN (SELECT col_id, 
                         col_code, 
                         col_name, 
                         col_activity 
                  FROM   tbl_dict_taskstate 
                  WHERE  Nvl(col_stateconfigtaskstate, 0) = (SELECT Nvl(col_stateconfigtasksystype, 0) 
                          FROM   tbl_dict_tasksystype 
                          WHERE 
                                 col_id = (SELECT col_taskccdict_tasksystype 
                                           FROM   tbl_taskcc 
                                           WHERE  col_id = v_taskid))) LOOP 
          INSERT INTO tbl_map_taskstateinitcc 
                      (col_map_taskstateinitcctaskcc, 
                       col_map_tskstinitcc_initmtd, 
                       col_map_tskstinitcc_tskst, 
                       col_code) 
          VALUES      (v_taskid, 
                       v_initmethodid, 
                       cur.col_id, 
                       Sys_guid()); 
      END LOOP; 
    END IF; 
END; 