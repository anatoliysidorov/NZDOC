/*
Sample rule for executing an event after the Case was updated.

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
    v_CustomDataXML XMLTYPE;    
    v_result INT;

BEGIN
	/*BASIC INFO*/
    v_CustomDataXML := XMLType(:CustomData);
    v_CaseId := :CaseId;
    :CaseExtId := 0; /*--this is legacy functionality. Leave it at 0*/
    
    v_result := f_HIST_createHistoryFn(AdditionalInfo=> 'This is a rule for testing AFTER CASE UPDATE',
                                       IsSystem=>0,
                                       MESSAGE=> 'This is a rule for testing AFTER CASE UPDATE',
                                       MessageCode => NULL,
                                       TargetID => v_CaseId,
                                       TargetType=>'CASE') ;
END;