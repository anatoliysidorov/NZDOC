SELECT tst.col_code AS code,
       tst.col_id AS id,
       tst.col_isdeleted AS isdeleted,
       tst.col_description AS description,
       tst.col_name AS NAME,
       tst.col_customdataprocessor AS CustomDataProcessor,
       cdp.name AS CustomDataProcessor_Name,
       tst.col_dateeventcustdataproc AS DateEventCustDataProc,
       de.name AS DateEventCustDataProc_Name,
       tst.col_processorcode AS ProcessorCode,
       pc.name AS ProcessorCode_Name,
       tst.col_retcustdataprocessor AS RetCustDataProcessor,
       rcdp.name AS RetCustDataProcessor_Name,
       tst.col_updatecustdataprocessor AS UpdateCustDataProcessor,
       ucpd.name AS UpdateCustDataProcessor_Name,
       tst.col_tasksystypeexecmethod AS ExecutionMethod_Id,
       tst.col_IconCode AS IconCode,
       dict_em.col_name AS ExecutionMethod_Name,
       dict_em.col_code AS ExecutionMethod_Code,
       NVL(dict_sc.col_id, 0) AS StateConfig_Id,
       NVL(dict_sc.col_name, 'Default') AS StateConfig_Name,
       (SELECT list_collect(CAST(COLLECT(To_char(rc.col_name) ORDER BY to_char(rc.col_name)) AS split_tbl), ', ', 1) AS ids
          FROM tbl_stp_resolutioncode rc
         INNER JOIN tbl_tasksystyperesolutioncode ttrc
            ON rc.col_id = ttrc.col_tbl_stp_resolutioncode
         WHERE tst.col_id = ttrc.col_tbl_dict_tasksystype) resolutioncodes_names,
       (SELECT list_collect(CAST(COLLECT(to_char(rc.col_id) ORDER BY to_char(rc.col_id)) AS split_tbl), '|||', 1) AS ids
          FROM tbl_stp_resolutioncode rc
         INNER JOIN tbl_tasksystyperesolutioncode ttrc
            ON rc.col_id = ttrc.col_tbl_stp_resolutioncode
         WHERE tst.col_id = ttrc.col_tbl_dict_tasksystype) resolutioncodes_ids,
       f_getNameFromAccessSubject(tst.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tst.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tst.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tst.col_modifiedDate) AS ModifiedDuration
         FROM tbl_dict_tasksystype tst
  LEFT JOIN tbl_dict_executionmethod dict_em
    ON dict_em.col_id = tst.col_tasksystypeexecmethod
  LEFT JOIN tbl_dict_StateConfig dict_sc
    ON dict_sc.col_id = tst.COL_STATECONFIGTASKSYSTYPE
  LEFT JOIN VW_UTIL_DEPLOYEDRULE cdp
    ON lower('f_'|| cdp.LOCALCODE) = tst.col_customdataprocessor
  LEFT JOIN VW_UTIL_DEPLOYEDRULE de
    ON lower('f_'|| de.LOCALCODE) = tst.col_dateeventcustdataproc
  LEFT JOIN VW_UTIL_DEPLOYEDRULE pc
    ON lower('f_'|| pc.LOCALCODE) = tst.col_processorcode
  LEFT JOIN VW_UTIL_DEPLOYEDRULE rcdp
    ON lower('f_'|| rcdp.LOCALCODE) = tst.col_retcustdataprocessor
  LEFT JOIN VW_UTIL_DEPLOYEDRULE ucpd
    ON lower('f_'|| ucpd.LOCALCODE) = tst.col_updatecustdataprocessor
 WHERE (:Id IS NULL OR (:Id IS NOT NULL AND tst.col_id = :Id))
   AND (:IsDeleted IS NULL OR (:IsDeleted IS NOT NULL AND tst.col_isdeleted = :IsDeleted))
   AND (:CODE IS NULL OR (lower(tst.col_Code) IN (SELECT lower(COLUMN_VALUE) FROM TABLE(ASF_SPLIT(:CODE, ',')))))
   AND (:UNIFIED_SEARCH IS NULL OR lower(tst.col_code) LIKE f_util_towildcards(:UNIFIED_SEARCH) OR lower(tst.col_name) LIKE f_util_towildcards(:UNIFIED_SEARCH) OR lower(tst.col_description) LIKE f_util_towildcards(:UNIFIED_SEARCH))
  AND (:NAME IS NULL OR (LOWER(tst.col_name) LIKE f_UTIL_toWildcards(:NAME)))
<%=SORT("@SORT@","@DIR@")%>