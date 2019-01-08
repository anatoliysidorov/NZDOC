DECLARE 
    v_result NUMBER; 
    v_taskid INTEGER; 
BEGIN 
    v_taskid := :TaskId; 

    BEGIN 
        SELECT Count(*) 
        INTO   v_result 
        FROM   (SELECT tsk.col_id AS TaskId 
                FROM   tbl_task tsk 
                       inner join tbl_ppl_workbasket wb 
                               ON tsk.col_taskppl_workbasket = wb.col_id 
                       inner join tbl_map_workbasketcaseworker mwbcw 
                               ON wb.col_id = mwbcw.col_map_wb_cw_workbasket 
                       inner join vw_ppl_activecaseworkersusers cwu 
                               ON mwbcw.col_map_wb_cw_caseworker = cwu.id 
                       inner join tbl_dict_workbaskettype wbt 
                               ON wb.col_workbasketworkbaskettype = wbt.col_id 
                WHERE  cwu.accode IN (SELECT accesssubject 
                                      FROM   TABLE(F_dcm_getproxyassignorlist()) 
                                     ) 
                UNION ALL 
                SELECT tsk.col_id AS TaskId 
                FROM   tbl_task tsk 
                       inner join tbl_ppl_workbasket wb 
                               ON tsk.col_taskppl_workbasket = wb.col_id 
                       inner join vw_ppl_activecaseworkersusers cwu 
                               ON wb.col_caseworkerworkbasket = cwu.id 
                WHERE  cwu.accode IN (SELECT accesssubject 
                                      FROM   TABLE(F_dcm_getproxyassignorlist()) 
                                     ) 
                       AND wb.col_isdefault = 1 
)
               s1 
        WHERE  s1.taskid = v_taskid; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_result := 0; 
    END; 

    RETURN CASE 
	 WHEN v_result > 0 THEN 1 
	 ELSE 0 
   END; 
END; 