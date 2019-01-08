SELECT ct.col_id                                                 AS ID, 
       ct.col_code                                               AS Code, 
       ct.col_description                                        AS Description, 
       ct.col_name                                               AS Name, 
       ct.col_showinportal                                       AS ShowInPortal, 
       ct.col_isdeleted                                          AS IsDeleted, 
       /*p.col_id                                                  AS Procedure_Id, 
       p.col_name                                                AS Procedure_Name, 
       p.col_code                                                AS Procedure_Code, */
       /*case when (1 in (select Allowed from table(f_DCM_getCWAOPermAccessMSFn(p_AccessObjectTypeCode => 'CASE_TYPE',p_PermissionCode =>'DETAIL')) where CaseTypeId = ct.col_id)) then 1
         else 0 end as PERM_CASETYPE_DETAIL,*/
       ------------------------------------------- 
       f_getNameFromAccessSubject(ct.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(ct.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(ct.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(ct.col_modifiedDate) AS ModifiedDuration
FROM   tbl_dict_casesystype ct 
--INNER JOIN tbl_procedure p on ct.col_id = p.COL_PROCEDUREDICT_CASESYSTYPE -- commented according task DCM-3103
WHERE 
    f_dcm_iscasetypeaccessalwms(AccessObjectId => (select Id from table(f_dcm_getCaseTypeAOList()) where CaseTypeId = ct.col_id)) = 1
    AND (:CASESYSTYPE_CODE IS NULL OR (lower(ct.col_Code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:CASESYSTYPE_CODE)))))
    --AND (:PROCEDURE_CODE IS NULL OR (lower(p.col_Code) in (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:PROCEDURE_CODE)))))    
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>