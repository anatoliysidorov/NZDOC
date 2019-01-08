SELECT eltype.COL_ID AS ID,
       eltype.COL_CODE AS CODE,
       eltype.COL_NAME AS NAME,
       eltype.COL_OWNER AS OWNER,
       f_getNameFromAccessSubject(eltype.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(eltype.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(eltype.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(eltype.col_modifiedDate) AS ModifiedDuration
  FROM tbl_fom_uielementtype eltype
 WHERE :ID IS NULL OR (:ID IS NOT NULL AND eltype.COL_ID = :ID)
<%=Sort("@SORT@","@DIR@")%>