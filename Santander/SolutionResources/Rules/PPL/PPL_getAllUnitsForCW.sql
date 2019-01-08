SELECT * 
FROM (
    SELECT s.col_id AS id,
           s.col_name AS name,
           s.col_code AS code,
           'SKILL_' || s.col_code AS calccode,
           TO_CHAR(s.col_description) AS description,
           'SKILL' AS objecttype,
           s.col_skillaccesssubject AS accesssubjectid
      FROM tbl_ppl_skill s LEFT JOIN tbl_caseworkerskill cws ON s.col_id = cws.col_tbl_ppl_skill
     WHERE cws.col_sk_ppl_caseworker = :CaseWorker_Id
    UNION ALL
    SELECT t.col_id AS id,
           t.col_name AS name,
           t.col_code AS code,
           'TEAM_' || t.col_code AS calccode,
           TO_CHAR(t.col_description) AS description,
           'TEAM' AS objecttype,
           t.col_teamaccesssubject AS accesssubjectid
      FROM tbl_ppl_team t LEFT JOIN tbl_caseworkerteam cwt ON t.col_id = cwt.col_tbl_ppl_team
     WHERE cwt.col_tm_ppl_caseworker = :CaseWorker_Id
    UNION ALL
    SELECT br.col_id AS id,
           br.col_name AS name,
           br.col_code AS code,
           'BUSINESSROLE_' || br.col_code AS calccode,
           TO_CHAR(br.col_description) AS description,
           'BUSINESSROLE' AS objecttype,
           br.col_businessroleaccesssubject AS accesssubjectid
      FROM tbl_ppl_businessrole br LEFT JOIN tbl_caseworkerbusinessrole cwr ON br.col_id = cwr.col_tbl_ppl_businessrole
     WHERE cwr.COL_br_PPL_CASEWORKER = :CaseWorker_Id
)
WHERE (:OBJECTTYPE is null or upper(:OBJECTTYPE) = objecttype)
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ") %>