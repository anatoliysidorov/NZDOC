SELECT te.col_id          AS id,
       te.COL_EXTSYSID    AS ExtSysId,
       te.col_name        AS NAME,
       te.col_firstname   AS firstname,
       te.col_middlename  AS middlename,
       te.col_lastname    AS lastname,
       te.col_prefix      AS prefix,
       te.col_suffix      AS suffix,
       te.col_dob         AS dob,
       te.col_code        AS code,
       te.col_phone       AS phone,
       te.col_email       AS email,
       te.col_address     AS address,
       te.col_description AS description,
       te.col_userid      AS userid,
       --te.col_isdeleted AS isdeleted,
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
       te.col_extpartypartyorgtype AS partyorgtype_id,
       dict_pot.col_code AS partyorgtype_code,
       dict_pot.col_name AS partyorgtype_name,
       ---------------------------------------------------------------
       f_getNameFromAccessSubject(te.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(te.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(te.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(te.col_modifiedDate) AS ModifiedDuration,
       ---------------------------------------------------------------

       -- count of related parties
       (SELECT COUNT(*) FROM tbl_externalparty ext1 WHERE ext1.col_extpartyextparty = te.col_Id) AS CountRelatedParties,
       --custom invoker
       dbms_xmlgen.CONVERT(f_ppl_getPartyCustomData(te.col_id)) AS CustomData,
       --path
       pathChain.parentChainNames AS parentChainNames,
       -- PAGE INFORMATION
       CASE
         WHEN :ID IS NULL THEN
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
  LEFT JOIN tbl_dict_partytype tdp ON tdp.col_id = te.col_externalpartypartytype
  --group_wb
  LEFT JOIN vw_ppl_simpleworkbasket group_wb ON group_wb.id = te.col_externalpartyworkbasket
  --primary personal wb
  LEFT JOIN vw_ppl_simpleworkbasket pp_wb ON pp_wb.externalparty_id = te.col_id
  LEFT JOIN tbl_ppl_team team ON team.col_id = te.col_defaultteam
  LEFT JOIN tbl_dict_partyorgtype dict_pot ON dict_pot.col_id = te.col_extpartypartyorgtype
 WHERE
    -- check on Active Caseworker
    f_DCM_getActiveCaseWorkerIdFn() > 0

    <%=IfNotNull(":ID", "AND te.col_id = :ID")%>
    <%=IfNotNull(":PartyType_Code", "AND LOWER(tdp.col_code) IN (select LOWER(to_char(regexp_substr(:PartyType_Code,'[[:'||'alnum:]_]+', 1, level))) as code from dual connect by dbms_lob.getlength(regexp_substr(:PartyType_Code, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>
    <%=IfNotNull(":PartyTypesPath", "AND LOWER(tdp.col_code) IN (select LOWER(to_char(regexp_substr(:PartyTypesPath,'[[:'||'alnum:]_]+', 1, level))) as code from dual connect by dbms_lob.getlength(regexp_substr(:PartyTypesPath, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>
    <%=IfNotNull(":ExtSysId", "AND LOWER(te.COL_EXTSYSID) = LOWER(:ExtSysId)")%>
    <%=IfNotNull(":PartyType_Id", "AND tdp.col_id = :PartyType_Id")%>
    <%=IfNotNull(":ParentExternalParty_Id", "AND te.col_extpartyextparty = :ParentExternalParty_Id")%>
    <%=IfNotNull(":NAME", "AND LOWER(te.col_name) LIKE F_UTIL_TOWILDCARDS(:NAME)")%>
    <%=IfNotNull(":PartOf", "AND LOWER(pathChain.parentChainNames) LIKE F_UTIL_TOWILDCARDS(:PartOf)")%>
    <%=IfNotNull(":ParentsName", "AND LOWER(pathChain.parentChainNames) LIKE F_UTIL_TOWILDCARDS(:ParentsName)")%>
    <%=IfNotNull(":Phone", "AND TO_CHAR(REGEXP_REPLACE(te.col_phone, '[^0-9]+', '')) LIKE F_UTIL_TOWILDCARDS(TO_CHAR(REGEXP_REPLACE(:Phone, '[^0-9]+', '')))")%>
    <%=IfNotNull(":Email", "AND LOWER(te.col_email) LIKE F_UTIL_TOWILDCARDS(:Email)")%>
    <%=IfNotNull(":PSEARCH", "AND LOWER(te.col_name) LIKE '%' || LOWER(:PSEARCH) || '%'")%>
    <%=IfNotNull(":IsDisabledManagement", "AND NVL(tdp.col_disablemanagement, 0) = :IsDisabledManagement")%>
    <%=IfNotNull(":LinkToUser_IDs", "AND te.col_userid IN (select TO_NUMBER(regexp_substr(:LinkToUser_IDs,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:LinkToUser_IDs, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>
    <%=IfNotNull(":CREATED_START", "AND TRUNC(te.col_createddate) >= TRUNC(TO_DATE(:CREATED_START))")%>
    <%=IfNotNull(":CREATED_END", "AND TRUNC(te.col_createddate) <= TRUNC(TO_DATE(:CREATED_END))")%>
    <%=IfNotNull(":PartyTypeIds", "AND tdp.col_id IN (select TO_NUMBER(regexp_substr(:PartyTypeIds,'[[:'||'alnum:]_]+', 1, level)) as id from dual connect by dbms_lob.getlength(regexp_substr(:PartyTypeIds, '[[:'||'alnum:]_]+', 1, level)) > 0)")%>

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>