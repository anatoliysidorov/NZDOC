DECLARE 
  type c_cursor is ref cursor;
  c_skills        c_cursor;
  c_teams         c_cursor;
  c_businessroles c_cursor;
  v_cwid          NUMBER;
  v_userid        NUMBER;
  
BEGIN
  select id, userid 
  into v_cwid, v_userid 
  from VW_PPL_CASEWORKERSUSERS 
  where accode = SYS_CONTEXT ('CLIENTCONTEXT', 'AccessSubject'); 
  
   OPEN c_skills FOR 
   'SELECT
      sk.col_id, sk.col_name, sk.col_code 
     FROM TBL_CASEWORKERSKILL cwsk
     LEFT JOIN tbl_ppl_skill sk ON cwsk.COL_TBL_PPL_SKILL = sk.col_id 
     WHERE COL_SK_PPL_CASEWORKER = ' || to_char(v_cwid);
    :cw_skills := c_skills;

   OPEN c_teams FOR 
   'SELECT 
      tm.col_id, tm.col_name, tm.col_code 
	 FROM TBL_CASEWORKERTEAM cwtm
	 LEFT JOIN tbl_ppl_team tm on cwtm.COL_TBL_PPL_TEAM = tm.col_id
	 WHERE COL_TM_PPL_CASEWORKER = ' || to_char(v_cwid);
    :cw_teams := c_teams;     

   OPEN c_businessroles FOR 
   'SELECT 
      br.col_id, br.col_name, br.col_code 
	 FROM TBL_CASEWORKERBUSINESSROLE cwbr
	 LEFT JOIN tbl_ppl_businessrole br on cwbr.COL_TBL_PPL_BUSINESSROLE = br.col_id
	 WHERE col_br_ppl_caseworker = ' || to_char(v_cwid);
    :cw_businessroles := c_businessroles;     

END;
