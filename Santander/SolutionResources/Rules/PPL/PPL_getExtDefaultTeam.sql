DECLARE
v_teamID        tbl_map_workbasketteam.col_map_wb_tm_team%TYPE;
BEGIN

  BEGIN
    SELECT tem.col_map_wb_tm_team
      INTO v_teamID     
    FROM tbl_externalparty ep,
         tbl_map_workbasketteam tem,
         vw_users u
    WHERE ep.col_externalpartyworkbasket =  tem.col_map_wb_tm_workbasket
      AND ep.col_userid = u.userid    
      AND u.AccessSubjectCode = (SELECT SYS_CONTEXT ('CLIENTCONTEXT', 'AccessSubject')FROM dual);
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
     :DefaultTeam_Id := null;
  END;
  
:DefaultTeam_Id :=v_teamID;        
END;