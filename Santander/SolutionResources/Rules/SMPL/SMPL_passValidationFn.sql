DECLARE 
    v_input  NCLOB; 
BEGIN 
    --Input--     
    v_input := :INPUT; 

	:ValidationResult := 1;
	:Message := 'No error';

	RETURN 0; 
END;