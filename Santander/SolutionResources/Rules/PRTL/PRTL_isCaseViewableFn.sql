DECLARE
  v_result INT := 0;
  v_count  INT := 0;
BEGIN
  IF (:Case_Id IS NOT NULL) THEN
    SELECT Count(t2.user_id) 
	INTO   v_count 
	FROM   vw_users u 
		   inner join (SELECT ep.col_id               AS EXTPARTY_ID, 
							  ep.col_extpartyextparty AS PARENTEXTPARTY_ID, 
							  ep.col_userid           AS USER_ID 
					   FROM   tbl_caseparty cp 
							  inner join tbl_externalparty ep 
									  ON ep.col_id = CP.col_casepartyexternalparty 
					   WHERE  cp.col_casepartycase = :Case_Id) t2 
				   ON t2.user_id = u.userid 
	WHERE  u.accesssubjectcode = :UserAccessSubject; 
  END IF;

  IF (v_count > 0) THEN
    v_result := 1;
  ELSE
    v_result := 0;
  END IF;

  RETURN v_result;
END;