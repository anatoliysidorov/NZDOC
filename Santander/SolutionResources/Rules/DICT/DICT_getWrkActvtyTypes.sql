SELECT col_id          AS WorkActivityType_Id,
       col_code        AS code,
       col_name        AS NAME,
       col_isdeleted   AS isdeleted,
       col_description AS description,
       col_iconcode    AS IconCode,
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_workactivitytype
 WHERE (:WorkActivityType_Id IS NULL OR col_id = :WorkActivityType_Id)
   AND (:ISDELETED IS NULL OR NVL(col_isdeleted, 0) = :ISDELETED)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>