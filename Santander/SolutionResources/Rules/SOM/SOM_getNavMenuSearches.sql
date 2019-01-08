SELECT sc.col_id   AS ConfigId,
       sc.col_name AS ConfigName,
       ct.col_id   AS CaseTypeId,
       ct.col_name AS CaseTypeName,
       ct.col_code AS CaseTypeCode
  FROM TBL_SOM_CONFIG sc
  LEFT JOIN tbl_som_model sm
    ON sm.col_id = sc.col_som_configsom_model
  LEFT JOIN tbl_mdm_model mm
    ON mm.col_id = sm.col_som_modelmdm_model
  LEFT JOIN tbl_dict_casesystype ct
    ON ct.col_casesystypemodel = sm.col_som_modelmdm_model
   AND NVL(ct.col_isdeleted, 0) = 0
 WHERE sc.col_isshowinnavmenu = 1
   AND NVL(mm.col_isdeleted, 0) = 0
   AND NVL(sc.col_isdeleted, 0) = 0
   AND ct.col_casesystypemodel IS NOT NULL
   AND (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = ct.col_id),
                               permissioncode => 'VIEW') = 1)
 ORDER BY LOWER(ct.col_name)