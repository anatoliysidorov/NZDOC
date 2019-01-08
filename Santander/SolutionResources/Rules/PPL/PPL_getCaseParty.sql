SELECT 
  prt.Id as Id,
  prt.Col_Id as Col_Id,
  prt.NAME as NAME,
  prt.AllowDelete as AllowDelete,
  prt.Case_Id as Case_Id,
  prt.CaseState_IsFinish as CaseState_IsFinish,
  prt.Description as Description,
  prt.PartyType_Id as PartyType_Id,
  prt.PartyType_Name as PartyType_Name,
  prt.PartyType_Code as PartyType_Code,
  dbms_xmlgen.CONVERT(prt.CustomConfig) AS CustomConfig,
  prt.CaseWorker_Id as CaseWorker_Id,
  prt.Team_Id as Team_Id,
  prt.BusinessRole_Id as BusinessRole_Id,
  prt.Skill_Id as Skill_Id,
  prt.ExternalParty_Id as ExternalParty_Id,
  prt.CALC_ID as CALC_ID,
  prt.CALC_NAME as CALC_NAME,
  prt.CALC_EMAIL as CALC_EMAIL,
  prt.CALC_EXTSYSID as CALC_EXTSYSID
FROM vw_ppl_caseparty prt
WHERE 1 = 1
  	<%= IfNotNull(":ID", " AND prt.id = :ID ") %>
    <%= IfNotNull(":Case_Id", " AND prt.case_id = :Case_Id ") %>
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ") %>

