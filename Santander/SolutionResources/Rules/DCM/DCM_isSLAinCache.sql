DECLARE
  v_count INTEGER;
  
BEGIN 
	v_count := 0;
	
    SELECT COUNT(1) INTO v_count
    FROM   tbl_slaactioncc 
    WHERE  col_id = :SLAACtionID;

	IF v_count = 0 THEN
		RETURN 0;
	ELSE 
		RETURN 1;
	END IF;
END;