WITH s
     AS (  SELECT prt.col_id AS id,
                  prt.col_code AS code,
                  prt.col_name AS description,
                  COUNT (prt.col_name) AS statistic,
                  prt.col_value AS VALUE
             FROM tbl_task tv
                  INNER JOIN tbl_case c
                     ON tv.col_casetask = c.col_id
                  INNER JOIN tbl_stp_priority prt
                     ON c.col_stp_prioritycase = prt.col_id
            WHERE tv.col_taskppl_workbasket in ((SELECT wb.col_id
                                        FROM  tbl_ppl_workbasket wb 
                                        INNER JOIN tbl_map_workbasketcaseworker mwbcw ON wb.col_id = mwbcw.col_map_wb_cw_workbasket
                                        INNER JOIN vw_ppl_activecaseworkersusers cwu ON mwbcw.col_map_wb_cw_caseworker = cwu.id
                                        INNER JOIN tbl_dict_workbaskettype wbt ON wb.col_workbasketworkbaskettype = wbt.col_id
                                        WHERE cwu.accode IN (SELECT accesssubject
                                                            FROM table(f_dcm_getproxyassignorlist()))
                                        UNION ALL
                                        (SELECT wb.col_id
                                        FROM tbl_ppl_workbasket wb 
                                        INNER JOIN vw_ppl_activecaseworkersusers cwu ON wb.col_caseworkerworkbasket = cwu.id
                                        WHERE cwu.accode IN (SELECT accesssubject
                                                            FROM table(f_dcm_getproxyassignorlist()))
                                              AND wb.col_isdefault = 1)))
         GROUP BY prt.col_id,
                  prt.col_code,
                  prt.col_name,
                  prt.col_value)
SELECT s.code,
       s.description,
       s.statistic,
       s.VALUE
  FROM s
 WHERE 1 = 1
 <%=IfNotNull(":codes", " and UPPER(s.code) IN (select to_char(regexp_substr(:codes,'[[:'||'alnum:]_]+', 1, level)) as code from dual connect by dbms_lob.getlength(regexp_substr(:codes, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>
 <%=IfNotNull(":codes", " and nvl(:show_all_count, 0) = 0")%>

UNION ALL
  SELECT prt.col_code AS code,
         prt.col_name AS description,
         0 AS statistic,
         prt.col_value AS VALUE
    FROM tbl_stp_priority prt
   WHERE prt.col_id NOT IN (SELECT s.id FROM s)
     AND nvl(:show_empty, 0) = 1
      <%=IfNotNull(":codes", " and UPPER(prt.col_code) IN (select to_char(regexp_substr(:codes,'[[:'||'alnum:]_]+', 1, level)) as code from dual connect by dbms_lob.getlength(regexp_substr(:codes, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>
GROUP BY prt.col_code,
         prt.col_name,
         prt.col_value

UNION ALL
SELECT CAST ('ALL' AS NVARCHAR2 (255)) AS code,
       CAST ('All Tasks' AS NVARCHAR2 (255)) AS description,
       (SELECT COUNT (*)
          FROM tbl_task tv
         WHERE tv.col_taskppl_workbasket in ((SELECT wb.col_id
                                        FROM  tbl_ppl_workbasket wb
                                        INNER JOIN tbl_map_workbasketcaseworker mwbcw ON wb.col_id = mwbcw.col_map_wb_cw_workbasket
                                        INNER JOIN vw_ppl_activecaseworkersusers cwu ON mwbcw.col_map_wb_cw_caseworker = cwu.id
                                        INNER JOIN tbl_dict_workbaskettype wbt ON wb.col_workbasketworkbaskettype = wbt.col_id
                                        WHERE cwu.accode IN (SELECT accesssubject
                                                            FROM table(f_dcm_getproxyassignorlist()))
                                        UNION ALL
                                        (SELECT wb.col_id
                                        FROM tbl_ppl_workbasket wb
                                        INNER JOIN vw_ppl_activecaseworkersusers cwu ON wb.col_caseworkerworkbasket = cwu.id
                                        WHERE cwu.accode IN (SELECT accesssubject
                                                            FROM table(f_dcm_getproxyassignorlist()))
                                              AND wb.col_isdefault = 1))))
          AS statistic,
       NULL AS VALUE
  FROM DUAL
 WHERE nvl(:show_all_count, 0) = 1