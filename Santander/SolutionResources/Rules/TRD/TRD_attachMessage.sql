DECLARE 
    v_result   NUMBER; 
    v_parentid INTEGER; 
    v_message  NCLOB; 
BEGIN 
    v_parentid := :ParentId; 
    v_message := :Message; 

    BEGIN 
        SELECT s1.threadid 
        INTO   v_result 
        FROM   (SELECT col_id                    AS ThreadId, 
                       Row_number() 
                         over ( 
                           ORDER BY col_id DESC) AS RowNumber 
                FROM   tbl_thread 
                WHERE  col_id = v_parentid 
                       AND Lower(col_status) = 'active') s1 
        WHERE  s1.rownumber = 1; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := 0; 

          RETURN 0; 
    END; 

    INSERT INTO tbl_thread 
                (col_code, 
                 col_datestarted, 
                 col_threadsourcetask, 
                 col_threadtargettask, 
                 col_message, 
                 col_datemessage, 
                 col_messageworkbasket, 
                 col_threadworkbasket, 
                 col_status, 
                 col_parentmessageid,
				 col_threadcase) 
    SELECT col_code, 
           col_datestarted, 
           col_threadsourcetask, 
           col_threadtargettask, 
           v_message, 
           SYSDATE, 
           (SELECT wb.col_id 
            FROM   vw_ppl_activecaseworkersusers cwu 
                   inner join tbl_ppl_workbasket wb 
                           ON cwu.id = wb.col_caseworkerworkbasket 
                   inner join tbl_dict_workbaskettype wbt 
                           ON wbt.col_id = wb.col_workbasketworkbaskettype 
                              AND wbt.col_code = 'PERSONAL'
            WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'accesssubject') AND wb.col_isdefault = 1) , 
           (SELECT wb.col_id 
            FROM   vw_ppl_activecaseworkersusers cwu 
                   inner join tbl_ppl_workbasket wb 
                           ON cwu.id = wb.col_caseworkerworkbasket 
                   inner join tbl_dict_workbaskettype wbt 
                           ON wbt.col_id = wb.col_workbasketworkbaskettype 
                              AND wbt.col_code = 'PERSONAL' 
            WHERE  cwu.accode = Sys_context('CLIENTCONTEXT', 'accesssubject')  AND wb.col_isdefault = 1), 
           col_status, 
           v_parentid,
			col_threadcase
    FROM   tbl_thread 
    WHERE  col_id = v_result; 

    SELECT gen_tbl_thread.CURRVAL 
    INTO   v_result 
    FROM   dual; 

    RETURN v_result; 
END;