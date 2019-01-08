DECLARE
  --input
  v_CaseTypeID INTEGER;
  --system
BEGIN
  --input
  v_CaseTypeID := :CaseTypeID;
  --system
  :ErrorCode    := 0;
  :ErrorMessage := '';

  --basic data
  OPEN :CUR_BASICDATA FOR
    SELECT COL_ID                       AS ID,
           COL_CODE                     AS CODE,
           COL_COLORCODE                AS COLORCODE,
           COL_CUSTOMDATAPROCESSOR      AS CUSTOMDATAPROCESSOR,
           COL_CUSTOMVALRESULTPROCESSOR AS CUSTOMVALRESULTPROCESSOR,
           COL_CUSTOMVALIDATOR          AS CUSTOMVALIDATOR,
           COL_DEBUGMODE                AS DEBUGMODE,
           COL_ICONCODE                 AS ICONCODE,
           COL_ISDELETED                AS ISDELETED,
           COL_ISDRAFTMODEAVAIL         AS ISDRAFTMODEAVAIL,
           COL_NAME                     AS NAME,
           COL_PROCESSORCODE            AS PROCESSORCODE,
           COL_RETCUSTDATAPROCESSOR     AS RETCUSTDATAPROCESSOR,
           COL_ROUTECUSTOMDATAPROCESSOR AS ROUTECUSTOMDATAPROCESSOR,
           COL_SHOWINPORTAL             AS SHOWINPORTAL,
           COL_UPDATECUSTDATAPROCESSOR  AS UPDATECUSTDATAPROCESSOR,
           COL_USEDATAMODEL             AS USEDATAMODEL,
           COL_CASESYSTYPEMODEL         AS CASESYSTYPEMODEL,
           COL_CASESYSTYPEPROCEDURE     AS CASESYSTYPEPROCEDURE,
           COL_CASETYPEPRIORITY         AS CASETYPEPRIORITY,
           COL_CASETYPEPROCINCASETYPE   AS CASETYPEPROCINCASETYPE,
           COL_DICTVERCASESYSTYPE       AS DICTVERCASESYSTYPE,
           COL_DEFAULTDOCFOLDER         AS DEFAULTDOCFOLDER,
           COL_DEFAULTMAILFOLDER        AS DEFAULTMAILFOLDER,
           COL_DEFAULTPORTALDOCFOLDER   AS DEFAULTPORTALDOCFOLDER,
           COL_STATECONFIGCASESYSTYPE   AS STATECONFIGCASESYSTYPE
      FROM TBL_DICT_CASESYSTYPE
     WHERE COL_ID = v_CaseTypeID;

  --documents
  OPEN :CUR_DOCUMENTS FOR
    SELECT * FROM VW_DOC_DOCUMENTS WHERE CASETYPEID = v_CaseTypeID;

  --access control
  OPEN :CUR_ACCESSCONTROL FOR
    SELECT ao.COL_ID   AS ID,
           ao.COL_CODE AS CODE,
           ao.COL_NAME AS NAME
      FROM TBL_AC_ACCESSOBJECT ao
     WHERE COL_ACCESSOBJECTCASESYSTYPE = v_CaseTypeID;

  OPEN :CUR_SPECIFICPERMISSIONS FOR
    SELECT acl.COL_ACLENTRY         AS ACLENTRY,
           acl.COL_CODE             AS CODE,
           acl.COL_ACLACCESSSUBJECT AS ASUBJ_ID,
           asubj.col_type           AS ASUBJ_TYPE,
           asubj.col_name           AS ASUBJ_NAME
      FROM TBL_AC_ACL acl
      LEFT JOIN TBL_AC_ACCESSSUBJECT asubj
        ON asubj.col_id = acl.COL_ACLACCESSSUBJECT
     WHERE acl.COL_ACLACCESSOBJECT = (SELECT COL_ID FROM TBL_AC_ACCESSOBJECT WHERE COL_ACCESSOBJECTCASESYSTYPE = v_CaseTypeID);

  OPEN :CUR_DEFAULTPERMISSIONS FOR
    SELECT p.COL_CODE,
           p.COL_DEFAULTACL,
           p.COL_ORDERACL
      FROM TBL_AC_PERMISSION p
     WHERE COL_PERMISSIONACCESSOBJTYPE = (SELECT COL_ID FROM TBL_AC_ACCESSOBJECTTYPE WHERE lower(COL_CODE) = 'case_type');

  --get participants for the Case Type
  OPEN :CUR_PARTICIPANTS FOR
    SELECT p.col_id AS Id,
           p.col_code AS Code,
           p.col_name AS NAME,
           p.col_isdeleted AS IsDeleted,
           p.col_description AS Description,
           p.col_participantdict_unittype AS UnitTypeId,
           pt.col_name AS UnitTypeName,
           pt.col_code AS UnitTypeCode,
           p.col_required AS Required,
           p.col_allowmultiple AS AllowMultiple,
           p.col_getprocessorcode AS ProcessorCode,
           p.col_getprocessorcode2 AS ProcessorCode2,
           dbms_xmlgen.CONVERT(p.col_customconfig) AS CustomConfig,
           p.col_participantbusinessrole AS BusinessRoleId,
           p.col_participantteam AS TeamId,
           p.col_participantppl_skill AS SkillId,
           p.col_participantppl_caseworker AS CaseWorkerId,
           p.col_participantexternalparty AS ExternalPartyId,
           p.col_participantcasesystype AS CaseSysTypeId,
           p.col_participantprocedure AS ProcedureId,
           p.col_isCreator AS IsCreator,
           p.col_isSupervisor AS IsSupervisor,
           CASE
             WHEN NVL(p.col_isCreator, 0) = 1 THEN
              1
             WHEN NVL(p.col_isSupervisor, 0) = 1 THEN
              2
             ELSE
              0
           END AS IsCreatorOrSupervisor
      FROM tbl_participant p
      LEFT JOIN tbl_dict_participantunittype pt
        ON pt.col_id = p.col_participantdict_unittype
      LEFT JOIN tbl_dict_casesystype ct
        ON ct.col_id = p.col_participantcasesystype
     WHERE p.col_participantcasesystype = v_CaseTypeID;

END;
