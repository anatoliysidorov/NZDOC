SELECT 
    so.COL_ID AS ID,
    so.COL_NAME AS NAME,
    so.COL_CODE AS CODE,
    so.COL_ISROOT AS ISROOT,
    so.COL_SOM_OBJECTSOM_MODEL AS MODELID,
    ct.COL_ID AS CASETYPEID
FROM tbl_SOM_Object so
  INNER JOIN tbl_SOM_Model sm ON so.col_SOM_ObjectSOM_Model = sm.COL_ID
  INNER JOIN tbl_MDM_Model mm ON sm.col_SOM_ModelMDM_Model = mm.COL_ID
  INNER JOIN tbl_DICT_CaseSysType ct ON ct.COL_CASESYSTYPEMODEL =  mm.COL_ID
WHERE 1 = 1
    AND so.COL_TYPE NOT IN ('parentBusinessObject', 'referenceObject')
    AND (:ID IS NULL OR so.COL_ID = :ID)
    AND (:CASETYPEID IS NULL OR ct.COL_ID = :CASETYPEID)
    AND (:MODELID IS NULL OR sm.COL_ID = :MODELID)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>