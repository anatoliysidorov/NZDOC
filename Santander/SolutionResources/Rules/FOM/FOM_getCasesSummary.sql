SELECT prt.col_code AS code,
       prt.col_name AS description,
       COUNT(prt.col_name) AS statistic,
       prt.col_value AS VALUE
  FROM tbl_case cv
 INNER JOIN tbl_stp_priority prt
    ON prt.col_id = cv.col_stp_prioritycase
 INNER JOIN vw_ppl_simpleworkbasket sw
    ON sw.id = cv.col_caseppl_workbasket
 INNER JOIN vw_ppl_activecaseworkersusers acu
    ON sw.caseworker_id = acu.id
 WHERE acu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
   AND lower(sw.workbaskettype_code) = 'personal'
   AND ((:CODES IS NULL AND NVL(:SHOW_ALL_COUNT, 0) = 0) OR
       UPPER(PRT.COL_CODE) IN
       (SELECT to_char(regexp_substr(:CODES, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS code FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:CODES, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0))

 GROUP BY prt.col_code,
          prt.col_name,
          prt.col_value

UNION ALL

SELECT PRT.COL_CODE  AS CODE,
       PRT.COL_NAME  AS DESCRIPTION,
       0             AS STATISTIC,
       PRT.COL_VALUE AS VALUE
  FROM TBL_STP_PRIORITY PRT
 WHERE PRT.COL_ID NOT IN (SELECT CV.col_stp_prioritycase
                            FROM tbl_case cv
                           INNER JOIN vw_ppl_simpleworkbasket sw
                              ON sw.id = cv.col_caseppl_workbasket
                           INNER JOIN vw_ppl_activecaseworkersusers acu
                              ON sw.caseworker_id = acu.id
                           WHERE acu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
                             AND lower(sw.workbaskettype_code) = 'personal')
   AND :CODES IS NOT NULL
   AND NVL(:SHOW_EMPTY, 0) = 1 
   <%=IfNotNull(":CODES", " AND UPPER(PRT.COL_CODE) IN (select to_char(regexp_substr(:CODES,'[[:'||'alnum:]_]+', 1, level)) as code from dual connect by dbms_lob.getlength(regexp_substr(:CODES, '[[:'||'alnum:]_]+', 1, level)) > 0) ") %>
 GROUP BY PRT.COL_CODE,
          PRT.COL_NAME,
          PRT.COL_VALUE

UNION ALL

SELECT CAST('ALL' AS NVARCHAR2(255)) AS CODE,
       CAST('All Cases' AS NVARCHAR2(255)) AS DESCRIPTION,
       (SELECT COUNT(*)
          FROM tbl_case CV
         INNER JOIN vw_ppl_simpleworkbasket sw
            ON sw.id = cv.col_caseppl_workbasket
         INNER JOIN vw_ppl_activecaseworkersusers acu
            ON sw.caseworker_id = acu.id
         WHERE acu.accode = Sys_context('CLIENTCONTEXT', 'AccessSubject')
           AND lower(sw.workbaskettype_code) = 'personal') AS STATISTIC,
       NULL AS VALUE
  FROM DUAL
 WHERE NVL(:SHOW_ALL_COUNT, 0) = 1
