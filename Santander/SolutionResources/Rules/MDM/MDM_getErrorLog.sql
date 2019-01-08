SELECT COL_ID as ID,
       COL_MDM_LOGMDM_MODEL as MDMMODELID,
       COL_MESSAGE as MESSAGE,
       /*-------------------------------------------*/
       f_getNameFromAccessSubject(col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(col_createdDate) AS CreatedDuration
       /*-------------------------------------------*/
FROM TBL_MDM_LOG
WHERE  COL_MDM_LOGMDM_MODEL = :MDMMODELID
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>