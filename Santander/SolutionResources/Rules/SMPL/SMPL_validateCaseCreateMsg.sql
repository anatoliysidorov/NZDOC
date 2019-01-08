/*
Sample rule for returning the error message after the validation rule.

Rule Type - SQL Non Query
Deploy as Function - Yes
Input 
	- ValidationResult (Integer)
	- CaseTypeId (Integer)
Output  
	- ValidationStatus (Integer) 0=continue creating case, 1=stop case creation
	- ErrorCode (Integer) 0 or any other integer
	- ErrorMessage (NCLOB)
*/

BEGIN
    
    CASE NVL(:ValidationResult,0)
    
    WHEN 0 THEN
        :validationstatus := 0;
        :ErrorCode        := 0;
        :ErrorMessage     := '';
    WHEN 501 THEN
        :validationstatus := 1;
        :ErrorCode        := :ValidationResult;
        :ErrorMessage     := 'There was an error processing the error message';
    WHEN 502 THEN
        :validationstatus := 1;
        :ErrorCode        := :ValidationResult;
        :ErrorMessage     := 'Problem 1 is incorrect';
    WHEN 503 THEN
        :validationstatus := 1;
        :ErrorCode        := :ValidationResult;
        :ErrorMessage     := 'Problem 2 is incorrect';
    WHEN 504 THEN
        :validationstatus := 1;
        :ErrorCode        := :ValidationResult;
        :ErrorMessage     := 'Problem 3 is incorrect';    
    ELSE
        :validationstatus := 1;
        :ErrorCode        := :ValidationResult;
        :ErrorMessage     := 'Unknow validation error';
    
    END CASE;

EXCEPTION
WHEN OTHERS THEN
    :validationstatus := 0;
    :ErrorCode := :ValidationResult;
    :ErrorMessage := 'There was an error processing the error message';
END;