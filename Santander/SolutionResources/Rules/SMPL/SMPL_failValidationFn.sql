DECLARE 
    v_input  NCLOB; 
BEGIN 
    --Input--     
    v_input := :INPUT; 

	:ValidationResult := 0;
	:Message := 'This is an example of a failed validation'; 

	RETURN 0; 
END;