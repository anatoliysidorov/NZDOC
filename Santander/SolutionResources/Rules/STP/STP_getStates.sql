SELECT s.col_id AS Id,
       s.col_name AS NAME,
       s.col_code AS Code,
       CASE
         WHEN s.col_statestateconfig IS NULL THEN
          'Default - ' || s.col_Name
         WHEN NVL(sc.col_iscurrent, 0) > 0 THEN
          sc.col_Name || '  - ' || s.col_Name
         ELSE
          sc.col_Name || ' (v' || to_char(sc.col_revision) || ') - ' || s.col_Name
       END AS CalcName,
       s.col_description AS Description,
       s.col_isdeleted AS IsDeleted,
       s.col_statestateconfig AS StateConfig_ID,
       CASE
         WHEN sc.col_Name IS NULL THEN
          NVL(sc.col_Name, 'Default')
         WHEN NVL(sc.col_iscurrent, 0) > 0 THEN
          sc.col_Name
         ELSE
          sc.col_Name || ' (v' || to_char(sc.col_revision) || ')'
       END AS StateConfig_Name,
       f_getNameFromAccessSubject(s.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(s.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(s.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(s.col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_state s
  LEFT JOIN tbl_dict_StateConfig sc
    ON (sc.col_id = s.col_statestateconfig)
 WHERE (:Id IS NULL OR s.col_id = :Id)
   AND (:IsDeleted IS NULL OR NVL(s.col_isdeleted, 0) = :IsDeleted)
   AND (:StateConfig_Id IS NULL OR s.col_statestateconfig = :StateConfig_Id)
   AND (:StateConfig_Code IS NULL OR LOWER(sc.col_code) = LOWER(:StateConfig_Code))
   AND (:STATECONFIGIDS IS NULL OR
       (s.col_statestateconfig IN (SELECT TO_NUMBER(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id
                                      FROM dual
                                    CONNECT BY dbms_lob.getlength(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)))
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 4")%>
