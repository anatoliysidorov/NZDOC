/*  
Sample of Validation Rule for determining whether the Case Milestone routing validation is allowed.

Rule Type - SQL Non Query  
Deploy as Function - Yes  
Input:  
  - CaseId, Integer  
  - Input, IN nclob  (collection of passed parameters in XML format)  

Output    
  - ValidationResult, Integer (0 = don't allow, 1 = allow)  
  - Message, Text Area  
*/ 
DECLARE 
    --INPUT    
    v_caseid NUMBER; 
    v_input  NCLOB; 
BEGIN 
    --Input--     
    v_caseid := :CASEID;
    v_input := :INPUT; 

    --CALCULATED--   
    --v_code := TRIM(LOWER(F_form_getparambyname(:Input, 'CODE')));   
    --OUTPUT--   
	
    IF v_caseid = 0 THEN 
      :ValidationResult := 1; 
      :Message := 'No error'; 
    ELSE 
      :ValidationResult := 0;
      :Message := 'You can not route this Case. This is an example of a validation event.'; 
	END IF; 

	RETURN 0; 
END; 