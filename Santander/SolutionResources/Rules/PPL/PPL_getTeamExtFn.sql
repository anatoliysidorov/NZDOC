DECLARE
	v_teamID        INTEGER;
	v_ParentExternalParty_Id        INTEGER;
	v_ParentExternalParty_Name        NVARCHAR2(255); 
	
BEGIN

  BEGIN
	SELECT ep.col_defaultteam, pep.col_id, pep.col_name  
	INTO   v_teamid, v_ParentExternalParty_Id, v_ParentExternalParty_Name
	FROM   tbl_externalparty ep 
		   INNER JOIN vw_users u ON (ep.col_userid = u.userid AND u.accesssubjectcode = Sys_context('CLIENTCONTEXT', 'AccessSubject'))
		   LEFT JOIN tbl_externalparty pep ON (pep.col_id = ep.COL_EXTPARTYEXTPARTY);
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
     v_teamID := NULL;
	 v_ParentExternalParty_Id := NULL;
	 v_ParentExternalParty_Name := NULL;
  END;  
  :DefaultTeam_Id := v_teamID;
  :ParentExternalParty_Id := v_ParentExternalParty_Id;
  :ParentExternalParty_Name := v_ParentExternalParty_Name; 
END;