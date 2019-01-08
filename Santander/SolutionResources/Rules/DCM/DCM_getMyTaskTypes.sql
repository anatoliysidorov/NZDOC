SELECT tst.col_code                                  AS code, 
       tst.col_id                                    AS id, 
       tst.col_isdeleted                             AS isdeleted, 
       tst.col_description                           AS description, 
       tst.col_name                                  AS name, 
       f_getNameFromAccessSubject(tst.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tst.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tst.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tst.col_modifiedDate) AS ModifiedDuration
FROM   tbl_dict_tasksystype tst 
WHERE
(:Id IS NULL OR (:Id IS NOT NULL AND tst.col_id = :Id )) AND
(:IsDeleted IS NULL OR (:IsDeleted IS NOT NULL AND tst.col_isdeleted = :IsDeleted )) AND
(:TASKSYSTYPE_CODE IS NULL OR (lower(tst.col_Code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:TASKSYSTYPE_CODE, ',')))))
<%=SORT("@SORT@","@DIR@")%>