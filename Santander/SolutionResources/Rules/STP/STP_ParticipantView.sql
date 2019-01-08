SELECT p.col_id AS Col_Id,
	   p.col_id AS Id,
       p.col_code AS Code,
       p.col_name AS Name,
       p.col_isowner AS IsOwner,
       p.col_required AS Required,
       p.col_isdeleted AS IsDeleted,
       p.col_allowmultiple AS AllowMultiple,
       p.col_description AS Description,
       -------------------------------------------------------  
       p.col_participantteam AS Team_Id,
       t.col_name AS Team_Name,
       t.col_code AS Team_Code,
       -------------------------------------------------------  
       p.col_participantbusinessrole AS BusinessRole_Id,
       br.col_name AS BusinessRole_Name,
       br.col_code AS BusinessRole_Code,
       -------------------------------------------------------  
       p.col_participantppl_caseworker AS CaseWorker_Id,
       cw.name AS CaseWorker_Name,
       cw.code AS CaseWorker_Code,
       -------------------------------------------------------  
       p.col_participantdict_partytype AS PartyType_Id,
       pt.col_code AS PartyType_Code,
       pt.col_name AS PartyType_Name,
       -------------------------------------------------------  
       p.col_participantcasesystype AS CaseType_Id,
       ct.col_name AS CaseType_Name,
       ct.col_code AS CaseType_Code,
       -------------------------------------------------------  
       p.col_participanttasksystype AS TaskType_Id,
       tt.col_name AS TaskType_Name,
       tt.col_code AS TaskType_Code,
       -------------------------------------------------------  
       F_getnamefromaccesssubject(p.col_createdby) AS CreatedBy_Name,
       F_UTIL_getDrtnFrmNow(p.col_createddate) AS CreatedDuration

  FROM TBL_PARTICIPANT p
  LEFT JOIN TBL_PPL_TEAM t
    ON (t.col_id = p.col_participantteam)
  LEFT JOIN TBL_PPL_BUSINESSROLE br
    ON (br.col_id = p.col_participantbusinessrole)
  LEFT JOIN VW_PPL_CASEWORKERSUSERS cw
    ON (cw.id = p.col_participantppl_caseworker)
  LEFT JOIN TBL_DICT_PARTYTYPE pt
    ON (pt.col_id = p.col_participantdict_partytype)
  LEFT JOIN TBL_DICT_CASESYSTYPE ct
    ON (ct.col_id = p.col_participantcasesystype)
  LEFT JOIN TBL_DICT_TASKSYSTYPE tt
    ON (tt.col_id = p.col_participanttasksystype)