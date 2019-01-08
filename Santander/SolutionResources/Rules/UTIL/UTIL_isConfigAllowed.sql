DECLARE 
    v_isdeleted      integer; 
BEGIN 
    SELECT col_isdeleted
    INTO   v_isdeleted 
    FROM   tbl_config
    WHERE  lower(col_name) = lower(:configName); 

	IF NVL(v_isdeleted, 0) = 0 THEN
		:IsAllowed := 1;
	ELSE 
		:IsAllowed := 0;
	END IF;
	
	EXCEPTION 
		WHEN no_data_found THEN 
			:IsAllowed := 0;
END; 