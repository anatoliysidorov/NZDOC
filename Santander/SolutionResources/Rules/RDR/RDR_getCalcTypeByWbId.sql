DECLARE 
    v_result VARCHAR2(255);
BEGIN 
    BEGIN
 SELECT 
 	CASE
      WHEN NVL(cw.col_id, 0) > 0 THEN 'Case Worker'
      WHEN NVL(t.col_id, 0) > 0 THEN 'Team'
      WHEN NVL(ep.col_id, 0) > 0 THEN 'External Party'
      WHEN NVL(s.col_id, 0) > 0 THEN 'Skill'
      WHEN NVL(br.col_id, 0) > 0 THEN 'Business Role'
      ELSE 'Other'
    END AS CalcType into v_result
    FROM   tbl_ppl_workbasket wb 
    LEFT JOIN tbl_ppl_caseworker cw ON (cw.col_id = wb.COL_CASEWORKERWORKBASKET)
    LEFT JOIN  vw_users u ON (u.userid = cw.col_userid)
    LEFT JOIN tbl_externalparty ep ON ( ep.col_id = wb.COL_WORKBASKETEXTERNALPARTY ) 
    LEFT JOIN tbl_ppl_team t ON (t.col_id = wb.COL_WORKBASKETTEAM)
    LEFT JOIN tbl_ppl_skill s ON (s.col_id = wb.COL_WORKBASKETSKILL)
    LEFT JOIN tbl_ppl_businessrole br ON (br.col_id = wb.COL_WORKBASKETBUSINESSROLE)
   where wb.col_id = :WorkbasketId;
      EXCEPTION 
        WHEN no_data_found THEN 
          v_result := 'NO DATA FOUND'; 
   END;
   RETURN v_result;
END;