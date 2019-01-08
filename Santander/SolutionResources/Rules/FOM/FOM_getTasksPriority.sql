SELECT code,
       description,
       statistic
  FROM (SELECT tst.col_code AS code,
               tst.col_name AS description,
               COUNT(tst.col_name) AS statistic
          FROM tbl_task t
          LEFT JOIN tbl_dict_tasksystype tst
            ON t.col_taskdict_tasksystype = tst.col_id
         WHERE t.col_taskppl_workbasket IN ((SELECT wb.col_id
                                              FROM tbl_ppl_workbasket wb
                                             INNER JOIN tbl_map_workbasketcaseworker mwbcw
                                                ON wb.col_id = mwbcw.col_map_wb_cw_workbasket
                                             INNER JOIN vw_ppl_activecaseworkersusers cwu
                                                ON mwbcw.col_map_wb_cw_caseworker = cwu.id
                                             INNER JOIN tbl_dict_workbaskettype wbt
                                                ON wb.col_workbasketworkbaskettype = wbt.col_id
                                             WHERE cwu.accode IN (SELECT accesssubject FROM TABLE(f_dcm_getproxyassignorlist()))
                                            UNION ALL (SELECT wb.col_id
                                                        FROM tbl_ppl_workbasket wb
                                                       INNER JOIN vw_ppl_activecaseworkersusers cwu
                                                          ON wb.col_caseworkerworkbasket = cwu.id
                                                       WHERE cwu.accode IN (SELECT accesssubject FROM TABLE(f_dcm_getproxyassignorlist()))
                                                         AND wb.col_isdefault = 1)))
        
         GROUP BY tst.col_code,
                  tst.col_name)
 WHERE 1 = 1
    <%= IfNotNull(":CODES", " and UPPER(code) IN (select to_char(regexp_substr(:CODES,'[[:'||'alnum:]_]+', 1, level)) as code from dual connect by dbms_lob.getlength(regexp_substr(:CODES, '[[:'||'alnum:]_]+', 1, level)) > 0) ")%>