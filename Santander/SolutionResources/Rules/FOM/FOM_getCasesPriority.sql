SELECT CODE,
       DESCRIPTION,
       STATISTIC
  FROM (SELECT cst.col_name AS CODE,
               cst.col_name AS DESCRIPTION,
               COUNT(cst.col_name) AS STATISTIC
          FROM tbl_case c
         INNER JOIN tbl_dict_casesystype cst
            ON c.col_casedict_casesystype = cst.col_id
         WHERE c.COL_CREATEDBY = sys_context('CLIENTCONTEXT', 'AccessSubject')
            OR c.col_caseppl_workbasket IN ((SELECT wb.col_id
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
         GROUP BY cst.col_code,
                  cst.col_name)
 WHERE 1 = 1
  <%= IfNotNull(":CODES", " AND UPPER(CODE) IN (select to_char(regexp_substr(:CODES,'[[:'||'alnum:]_]+', 1, level)) as code from dual connect by dbms_lob.getlength(regexp_substr(:CODES, '[[:'||'alnum:]_]+', 1, level)) > 0) ") %>