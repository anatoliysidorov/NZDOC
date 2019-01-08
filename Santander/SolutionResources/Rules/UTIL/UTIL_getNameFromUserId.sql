DECLARE 
    v_name      NVARCHAR2(255); 
BEGIN 
    SELECT name
    INTO   v_name 
    FROM   vw_users
    WHERE  userid = :p_userid; 

    RETURN v_name; 
	
	EXCEPTION 
		WHEN no_data_found THEN 
			RETURN ''; 
END; 