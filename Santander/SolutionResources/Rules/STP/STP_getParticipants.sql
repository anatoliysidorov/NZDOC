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
       END AS IsCreatorOrSupervisor,
       f_getNameFromAccessSubject(p.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(p.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(p.col_modifiedDate) AS ModifiedDuration
  FROM tbl_participant p
  LEFT JOIN tbl_dict_participantunittype pt
    ON pt.col_id = p.col_participantdict_unittype
  LEFT JOIN tbl_dict_casesystype ct
    ON ct.col_id = p.col_participantcasesystype
 WHERE (:Id IS NULL OR p.col_id = :Id)
   AND (:CaseSysTypeId IS NULL OR p.col_participantcasesystype = :CaseSysTypeId)
   AND (:ProcedureId IS NULL OR p.col_participantprocedure = :ProcedureId)
   AND (:MilestoneId IS NULL OR (ct.COL_ID = (SELECT sc.col_casesystypestateconfig FROM TBL_DICT_STATECONFIG SC WHERE SC.COL_ID = :MilestoneId)))
   AND (:TaskSysTypeId IS NULL OR p.col_participanttasksystype = :TaskSysTypeId)
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>