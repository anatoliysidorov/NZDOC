SELECT sConf.COL_ID AS Id,
       sConf.COL_NAME AS Name,
       sConf.COL_CODE AS Code,
       sConf.COL_ISDELETED AS IsDeleted,
       sConf.COL_DESCRIPTION AS Description,
       fObj.COL_ID AS PrimaryObject_Id,
       fObj.COL_NAME AS PrimaryObject_Name,
       fObj.COL_CODE AS PrimaryObject_Code,
       sConf.COL_DEFSORTFIELD AS DefaultSortField,
       sConf.COL_SORTDIRECTION AS DefaultSortDirection,
       f_getNameFromAccessSubject(sConf.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(sConf.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(sConf.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(sConf.col_modifiedDate) AS ModifiedDuration
  FROM tbl_som_config sConf 
LEFT JOIN TBL_FOM_OBJECT fObj ON fObj.COL_ID = sConf.COL_SOM_CONFIGFOM_OBJECT
 WHERE :Id IS NULL OR (:Id IS NOT NULL AND sConf.COL_ID = :Id)
<%=Sort("@SORT@","@DIR@")%>