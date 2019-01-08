SELECT *
FROM (
	SELECT 
		s.col_id AS id,
		s.col_name AS name,
		s.col_code AS code,
		TO_CHAR(s.col_description) AS description,
		'SKILL' AS objecttype,
		s.col_skillaccesssubject AS accesssubjectid
	FROM tbl_ppl_skill s 
	WHERE s.col_id not in (
		SELECT cws.COL_TBL_PPL_SKILL
		FROM tbl_caseworkerskill cws
		WHERE cws.col_sk_ppl_caseworker = :CaseWorker_Id
	)
UNION ALL
	SELECT 
		t.col_id AS id,
		t.col_name AS name,
		t.col_code AS code,
		TO_CHAR(t.col_description) AS description,
		'TEAM' AS objecttype,
		t.col_teamaccesssubject AS accesssubjectid
	FROM tbl_ppl_team t 
	WHERE t.col_id not in (
		SELECT cwt.COL_TBL_PPL_TEAM
		FROM TBL_CASEWORKERTEAM cwt
		WHERE cwt.col_tm_ppl_caseworker = :CaseWorker_Id
	)
UNION ALL
	SELECT 
		br.col_id AS id,
		br.col_name AS name,
		br.col_code AS code,
		TO_CHAR(br.col_description) AS description,
		'BUSINESSROLE' AS objecttype,
		br.col_businessroleaccesssubject AS accesssubjectid
	FROM tbl_ppl_businessrole br 
	WHERE br.col_id not in (
		SELECT cwr.COL_TBL_PPL_BUSINESSROLE
		FROM TBL_CASEWORKERBUSINESSROLE cwr
		WHERE cwr.COL_BR_PPL_CASEWORKER = :CaseWorker_Id
	)
)
WHERE (:OBJECTTYPE is null or upper(:OBJECTTYPE) = objecttype)
<%= IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1 ") %>