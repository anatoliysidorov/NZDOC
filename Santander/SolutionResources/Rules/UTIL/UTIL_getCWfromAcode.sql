DECLARE 
    v_result NVARCHAR2(255); 
BEGIN
	BEGIN
		SELECT id 
		INTO   v_result 
		FROM   VW_PPL_CASEWORKERSUSERS
		WHERE  ACCODE = :AccessSubjectCode; 
	EXCEPTION
	   when no_data_found then
		v_result := null; 
	END;

	RETURN v_result; 
END; 