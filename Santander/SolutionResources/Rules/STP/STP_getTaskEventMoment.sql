SELECT col_id AS ID,
       col_code AS CODE,
       col_name AS NAME,
       -------------------------------------------
       f_getNameFromAccessSubject (col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow (col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject (col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow (col_modifiedDate) AS ModifiedDuration
  FROM tbl_DICT_TaskEventMoment
 WHERE (:Id IS NULL OR col_id = :Id)
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%> 