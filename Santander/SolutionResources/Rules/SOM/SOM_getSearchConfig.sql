SELECT sc.COL_ID AS ID,
       sc.COL_NAME AS NAME,
       fo.COL_CODE AS OBJECTCODE,
       sc.COL_GRIDCONFIG AS GRIDCONFIG,
       sc.COL_SEARCHCONFIG AS SEARCHCONFIG,
       fc.col_id AS FORMID,
       fc.COL_NAME AS FORMNAME,
       fc.COL_CODE AS FORMCODE,
       fu.col_id AS FORMIDUPDATE,
       fu.COL_NAME AS FORMNAMEUPDATE,
       fu.COL_CODE AS FORMCODEUPDATE,
       ct.COL_ID AS CASETYPEID,
       ct.COL_ISDRAFTMODEAVAIL AS ISDRAFTMODEAVAIL,
       DECODE (NVL (ct.col_casetypepriority, 0), 0, prty_def.priority_id, ct.col_casetypepriority) AS DEFAULTPRIORITY,
       so.COL_ISROOT AS ISROOTOBJECT,
       (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = ct.col_id),
                               permissioncode => 'CREATE')) AS ISALWCREATE
  FROM TBL_SOM_CONFIG sc
 INNER JOIN tbl_SOM_Model sm
    ON sm.col_id = sc.COL_SOM_CONFIGSOM_MODEL
 INNER JOIN tbl_MDM_Model mm
    ON mm.col_id = sm.COL_SOM_MODELMDM_MODEL
 INNER JOIN tbl_FOM_OBJECT fo
    ON fo.col_Id = sc.COL_SOM_CONFIGFOM_OBJECT
 INNER JOIN tbl_SOM_OBJECT so
    ON so.COL_SOM_OBJECTFOM_OBJECT = fo.col_id
  LEFT JOIN TBL_DICT_CASESYSTYPE ct
    ON ct.COL_CASESYSTYPEMODEL = mm.col_id
  LEFT JOIN (SELECT col_id AS priority_id FROM tbl_stp_priority WHERE NVL (col_isdefault, 0) = 1 AND NVL (col_isdeleted, 0) = 0) prty_def
    ON 1 = 1
  LEFT JOIN tbl_MDM_SEARCHPAGE spc
    ON spc.col_searchpagesom_config = sc.col_id
   AND spc.COL_FORMMODE = 'CREATE'
  LEFT JOIN tbl_MDM_SEARCHPAGE spu
    ON spu.col_searchpagesom_config = sc.col_id
   AND spu.COL_FORMMODE = 'UPDATE'
  LEFT JOIN tbl_MDM_FORM fc
    ON fc.col_id = spc.COL_SEARCHPAGEMDM_FORM
  LEFT JOIN tbl_MDM_FORM fu
    ON fu.col_id = spu.COL_SEARCHPAGEMDM_FORM
 WHERE (ROWNUM = 1 AND sc.COL_ID = :ConfigId)
   AND (:CaseTypeCode IS NULL OR UPPER(ct.col_code) = :CaseTypeCode)