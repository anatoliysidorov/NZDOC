DECLARE
v_extPartyId    tbl_externalparty.col_id%TYPE;
v_teamID        tbl_map_workbasketteam.col_map_wb_tm_team%TYPE;
BEGIN
v_extPartyId:= :ExtPartyID;

  BEGIN
    SELECT tem.col_map_wb_tm_team
      INTO v_teamID     
    FROM tbl_externalparty ep,
         tbl_map_workbasketteam tem
    WHERE ep.col_externalpartyworkbasket =  tem.col_map_wb_tm_workbasket
      AND ep.col_id = v_extPartyId;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
     v_teamID := 0;
     RETURN -1;
  END;
  
RETURN  v_teamID;        

END;