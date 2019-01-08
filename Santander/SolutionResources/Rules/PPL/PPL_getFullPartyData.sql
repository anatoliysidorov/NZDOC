DECLARE
  --INPUT
  v_party_id INTEGER;

  v_Counters SYS_REFCURSOR;
  v_result   NUMBER;
BEGIN
  --INPUT
  v_party_id := :PARTY_ID;

  --GET DATA IF PARTYID IS PRESENT
  IF v_party_id > 0 THEN
    OPEN :CUR_DATA FOR
      SELECT te.col_id AS id,
             te.COL_EXTSYSID AS ExtSysId,
             te.col_name AS NAME,
             te.col_firstname AS firstname,
             te.col_middlename AS middlename,
             te.col_lastname AS lastname,
             te.col_prefix AS prefix,
             te.col_suffix AS suffix,
             te.col_dob AS dob,
             te.col_code AS code,
             te.col_phone AS phone,
             te.col_email AS email,
             te.col_address AS address,
             te.col_description AS description,
             te.col_userid AS userid,
             F_util_getnamefromuserid(te.col_userid) AS userid_name,
             te.col_extpartyextparty AS parentexternalparty_id,
             team.col_id AS DEFAULTTEAM_ID,
             team.col_name AS DEFAULTTEAM_NAME,
             pp_wb.id AS personalworkbasket_id, --primary personal wb
             pp_wb.calcname AS personalworkbasket_name,
             te.col_externalpartyworkbasket AS workbasket_id, --group_wb
             group_wb.calcname AS workbasket_name,
             group_wb.workbaskettype_name AS workbasket_type_name,
             group_wb.workbaskettype_code AS workbasket_type_code,
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
             (SELECT COUNT(*) FROM tbl_externalparty ext1 WHERE ext1.col_extpartyextparty = te.col_Id) AS CountRelatedParties,
             --custom invoker
             f_ppl_getPartyCustomData(te.col_id) AS CustomData,
             --path
             pathChain.parentChainNames AS parentChainNames,
             -- PAGE INFORMATION
             CASE
               WHEN v_party_id IS NULL THEN
                NULL
               ELSE
                f_dcm_getpageid(entity_id => te.col_id, entity_type => 'extparty')
             END AS DesignerPage_Id
        FROM tbl_externalparty te
        LEFT JOIN (SELECT ep.col_id AS ID,
                          LTRIM(SYS_CONNECT_BY_PATH(ep.col_name, '|||'), '|||') AS parentChainNames
                     FROM tbl_externalparty ep
                    START WITH NVL(Ep.col_extpartyextparty, 0) = 0
                   CONNECT BY NVL(Ep.col_extpartyextparty, 0) = PRIOR NVL(Ep.col_id, 0)) pathChain
          ON pathChain.id = te.col_extpartyextparty
        LEFT JOIN tbl_dict_partytype tdp
          ON tdp.col_id = te.col_externalpartypartytype
      --group_wb
        LEFT JOIN vw_ppl_simpleworkbasket group_wb
          ON group_wb.id = te.col_externalpartyworkbasket
      --primary personal wb
        LEFT JOIN vw_ppl_simpleworkbasket pp_wb
          ON pp_wb.externalparty_id = te.col_id
        LEFT JOIN tbl_ppl_team team
          ON team.col_id = te.col_defaultteam
       WHERE te.col_id = v_party_id;
  
    -- GET COUNTERS DATA
    v_result      := f_DCM_getObjectCountsFn(CaseId => NULL, TaskId => NULL, ExternalPartyId => v_party_id, ITEMS => v_Counters);
    :CUR_COUNTERS := v_Counters;
  
  END IF;

END;
