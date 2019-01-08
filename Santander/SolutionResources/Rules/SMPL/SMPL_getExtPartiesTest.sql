SELECT te.col_id AS id,
       te.COL_EXTSYSID AS ExtSysId,
       te.col_name AS name,
       te.col_phone AS phone,
       te.col_email AS email,
       te.col_address AS address,
       te.col_description AS description,
       te.col_userid AS userid,
       --te.col_isdeleted AS isdeleted,
       F_util_getnamefromuserid(te.col_userid) AS userid_name,
       te.col_extpartyextparty AS parentexternalparty_id,
       team.col_id AS DEFAULTTEAM_ID,
       team.col_name AS DEFAULTTEAM_NAME,

       te.col_externalpartyworkbasket AS workbasket_id,
       wb.calcname AS workbasket_name,
       wb.workbaskettype_name AS workbasket_type_name,
       wb.workbaskettype_code AS workbasket_type_code,
       
       te.col_externalpartypartytype AS partytype_id,
       tdp.col_name AS partytype_name,
       tdp.col_code AS partytype_code,
       tdp.col_isdeleted AS isdeleted,
       ---------------------------------------------------------------
       f_getNameFromAccessSubject(te.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(te.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(te.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(te.col_modifiedDate) AS ModifiedDuration,
       ---------------------------------------------------------------

       -- count of related parties
       (SELECT COUNT(*) 
       FROM tbl_externalparty ext1
       WHERE ext1.col_extpartyextparty = te.col_Id) AS CountRelatedParties,

       --custom invoker
       f_ppl_getPartyCustomData(te.col_id) AS CustomData,
       --path
       pathChain.parentChainNames AS parentChainNames
  FROM tbl_externalparty te
       LEFT JOIN (    SELECT ep.col_id AS ID, LTRIM(SYS_CONNECT_BY_PATH(ep.col_name, '|||'), '|||') AS parentChainNames
                        FROM tbl_externalparty ep
                  START WITH NVL(Ep.col_extpartyextparty, 0) = 0
                  CONNECT BY NVL(Ep.col_extpartyextparty, 0) = PRIOR NVL(Ep.col_id, 0)) pathChain
          ON pathChain.id = te.col_extpartyextparty
       LEFT JOIN tbl_dict_partytype tdp
          ON tdp.col_id = te.col_externalpartypartytype
       LEFT JOIN vw_ppl_simpleworkbasket wb
          ON wb.id = te.col_externalpartyworkbasket
       LEFT JOIN tbl_ppl_team team
          ON team.col_id = te.col_defaultteam
 WHERE 1=1
       AND (LOWER(te.col_email) LIKE F_UTIL_TOWILDCARDS('gmail.com'))
 