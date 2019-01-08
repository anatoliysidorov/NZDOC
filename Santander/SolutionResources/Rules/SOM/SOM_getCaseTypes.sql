SELECT 
  ct.col_id AS Id,
  ct.col_code AS Code,
  ct.col_name AS Name,
  ct.col_description AS Description,
  ct.col_colorcode AS Colorcode,
  ct.col_iconcode AS IconCode,
  sm.col_id AS ModelId,
  sm.col_name AS ModelName,
  sm.col_code AS ModelCode
  
FROM tbl_DICT_CaseSysType ct
  INNER JOIN tbl_MDM_Model mm ON ct.col_casesystypemodel = mm.col_id
  INNER JOIN tbl_SOM_Model sm ON mm.col_id = sm.col_SOM_ModelMDM_Model
WHERE 1 =1 
  AND (:CaseType_Id IS NULL OR ct.col_id = :CaseType_Id)
  AND (:Model_Id IS NULL OR sm.col_id = :Model_Id)
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>