DECLARE 
    v_result    NUMBER; 
    v_srctaskid INTEGER; 
    v_trgtaskid INTEGER; 
    v_message   NCLOB; 
BEGIN 
    v_srctaskid := :SourceTaskId; 
    v_trgtaskid := :TargetTaskId; 
    v_message := :Message; 

    BEGIN 
        SELECT s1.threadid 
        INTO   v_result 
        FROM   (SELECT col_id                    AS ThreadId, 
                       Row_number() 
                         over ( 
                           ORDER BY col_id DESC) AS RowNumber 
                FROM   tbl_thread 
                WHERE  col_threadsourcetask = v_srctaskid 
                       AND col_threadtargettask = v_trgtaskid 
                       AND Lower(col_status) = 'active') s1 
        WHERE  s1.rownumber = 1; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := 0; 
    END; 

    IF v_result > 0 THEN 
      RETURN v_result; 
    END IF; 

    INSERT INTO tbl_thread 
                (col_code, 
                 col_datestarted, 
                 col_threadsourcetask, 
                 col_threadtargettask, 
                 col_datemessage, 
                 col_message, 
                 col_messageworkbasket, 
                 col_threadworkbasket, 
                 col_status, 
                 col_parentmessageid) 
    VALUES     (Sys_guid(), 
                SYSDATE, 
                v_srctaskid, 
                v_trgtaskid, 
                SYSDATE, 
                v_message, 
                (SELECT wb.col_id 
                 FROM   vw_ppl_activecaseworkersusers cwu 
                        inner join tbl_ppl_workbasket wb 
                                ON cwu.id = wb.col_caseworkerworkbasket 
                        inner join tbl_dict_workbaskettype wbt 
                                ON wbt.col_id = wb.col_workbasketworkbaskettype 
                                   AND wbt.col_code = 'PERSONAL' 
                 WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 
                                     'accesssubject')), 
                (SELECT wb.col_id 
                 FROM   vw_ppl_activecaseworkersusers cwu 
                        inner join tbl_ppl_workbasket wb 
                                ON cwu.id = wb.col_caseworkerworkbasket 
                        inner join tbl_dict_workbaskettype wbt 
                                ON wbt.col_id = wb.col_workbasketworkbaskettype 
                                   AND wbt.col_code = 'PERSONAL' 
                 WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 
                                     'accesssubject')), 
                'ACTIVE', 
                0); 

    SELECT gen_tbl_thread.CURRVAL 
    INTO   v_result 
    FROM   dual; 

    RETURN v_result; 
END; 