SELECT cs.col_id AS Id,
       cs.col_name AS NAME,
       cs.col_code AS Code,
       CASE
         WHEN cs.col_stateconfigcasestate IS NULL THEN
          'Default - ' || cs.col_Name
         ELSE
          sc.col_Name || ' - ' || cs.col_Name
       END AS CalcName,
       cs.col_description AS Description,
       cs.col_isdeleted AS IsDeleted,
       cs.col_stateconfigcasestate AS StateConfig_ID,
       NVL(sc.col_Name, 'Default') AS StateConfig_Name,
       f_getNameFromAccessSubject(cs.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(cs.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(cs.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(cs.col_modifiedDate) AS ModifiedDuration
  FROM tbl_dict_casestate cs
  LEFT JOIN tbl_dict_StateConfig sc
    ON (sc.col_id = cs.col_stateconfigcasestate)
 WHERE 1 = 1
 <%=IfNotNull(":Id", "AND cs.col_id = :Id")%>
 <%=IfNotNull(":IsDeleted", "AND NVL(cs.col_isdeleted, 0) = :IsDeleted")%>
 <%=IfNotNull(":StateConfig_Id", "AND cs.col_stateconfigcasestate = :StateConfig_Id")%>
 <%=IfNotNull(":StateConfig_Code", "AND LOWER(sc.col_code) = LOWER(:StateConfig_Code)")%>
 <%=IfNotNull(":STATECONFIGIDS", "AND cs.col_stateconfigcasestate IN (SELECT TO_NUMBER(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:STATECONFIGIDS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)")%>

<%=Filter(OPTION=:CalcName_OPTION, VALUE1=:CalcName, FIELD=CASE WHEN cs.col_stateconfigcasestate IS NULL THEN 'Default - ' || cs.col_Name ELSE sc.col_Name || ' - ' || cs.col_Name END)%>
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>
