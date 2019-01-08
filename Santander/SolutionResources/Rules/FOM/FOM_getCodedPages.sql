SELECT cp.col_Id          AS Id,
       cp.col_Name        AS Name,
       cp.col_Code        AS Code,
       cp.col_description AS Description,
       cp.col_isDeleted   AS IsDeleted,
       cp.col_IsNavMenuItem   AS IsNavMenuItem,
       dbms_xmlgen.CONVERT(cp.col_PageMarkup) AS PageMarkup,
       -------------------------------------------
       f_getNameFromAccessSubject(cp.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(cp.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(cp.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(cp.col_modifiedDate) AS ModifiedDuration
       -------------------------------------------
FROM   tbl_FOM_CodedPage cp
WHERE  (:CodedPage_Id IS NULL OR cp.col_id = :CodedPage_Id )
    AND (:CodedPage_Code IS NULL OR UPPER(cp.col_Code) = UPPER(:CodedPage_Code) )
    AND(:IsDeleted IS NULL OR NVL(cp.col_isDeleted,0) = :IsDeleted )
    AND(:IsNavMenuItem IS NULL OR NVL(cp.col_IsNavMenuItem,0) = :IsNavMenuItem )
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>