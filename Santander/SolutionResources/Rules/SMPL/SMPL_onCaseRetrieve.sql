/*
Sample rule for executing an event on the Case was retrieved.

Rule Type - SQL Non Query
Deploy as Function - Yes
Input 
- CaseId (Integer)
- CustomData (NCLOB)
Output
- CaseExtId (Integer) optional (legacy)
*/

DECLARE
    v_CaseId INTEGER;
    v_result INT;

BEGIN
	/*BASIC INFO*/
    v_CaseId := :CaseId;
    :OutData := 'This is a rule for testing ON CASE RETRIEVE';
    
END;
