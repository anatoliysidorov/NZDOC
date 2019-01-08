SELECT sc.col_id AS Id,
       sc.col_name AS NAME,
       sc.col_code AS Code,
       sc.col_isdeleted AS IsDeleted,
       --sc.col_config AS Config,
       dbms_xmlgen.CONVERT(sc.col_config) AS Config,
       sc.col_iconcode AS IconCode,
       sc.col_isdefault AS IsDefault,
       ---------------------------------------------------------------
       f_getNameFromAccessSubject (sc.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow (sc.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject (sc.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow (sc.col_modifiedDate) AS ModifiedDuration,
       ---------------------------------------------------------------
       (SELECT COUNT (*)
          FROM tbl_DICT_CaseSysType cst INNER JOIN tbl_Case c ON (c.COL_CASEDICT_CASESYSTYPE = cst.col_Id)
         WHERE cst.col_stateconfigcasesystype = sc.col_Id)
          AS CASESCOUNT,
       sc.col_casesystypestateconfig AS CaseTypeId
  FROM tbl_dict_stateconfig sc   
 WHERE (:Id IS NULL OR sc.col_id = :Id)
       AND (:CaseTypeId IS NULL OR (sc.col_casesystypestateconfig = :CaseTypeId and sc.col_iscurrent = 1))      
       AND (:TYPE IS NULL OR sc.col_type = :TYPE)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>