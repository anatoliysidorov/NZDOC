/*
Sample rule for validating a math test.

Rule Type - SQL Non Query
Deploy as Function - Yes
Input - CustomData (NCLOB)
Output  
	- CaseId (Integer) optional
	- ValidationResult (Integer) 0 or any other integer
*/

DECLARE
    v_CaseId INTEGER;
    v_CustomDataXML XMLTYPE;

    /*--case fields*/
    v_SUMMARY NCLOB;
    v_DESCRIPTION NCLOB;
    v_PRIORITY_ID    INT;
    v_CASESYSTYPE_ID INT;
    v_WORKBASKET_ID  INT;
    v_DRAFT          INT;

    /*--math problem fields*/
    v_PROBLEM1 INT;
    v_PROBLEM2 INT;
    v_PROBLEM3 INT;

BEGIN
	/*BASIC INFO*/
    v_CustomDataXML := XMLType(:CustomData) ;
	:CaseId := 0; --this is legacy functionality. Leave it at 0

	/*PARSE INPUT XML TO GET CASE DATA*/
    SELECT  SUMMARY,
            DESCRIPTION,
            PRIORITY_ID,
            CASESYSTYPE_ID,
            WORKBASKET_ID,
            DRAFT
    INTO    v_SUMMARY,
            v_DESCRIPTION,
            v_PRIORITY_ID,
            v_CASESYSTYPE_ID,
            v_WORKBASKET_ID,
            v_DRAFT
    FROM    XMLTABLE('/CustomData/Attributes/Object/Item[OBJECTCODE="CASE"]'
            PASSING v_CustomDataXML
            COLUMNS SUMMARY NCLOB     PATH 'SUMMARY',
                    DESCRIPTION NCLOB PATH 'DESCRIPTION',
                    PRIORITY_ID    INT   PATH 'PRIORITY_ID',
                    CASESYSTYPE_ID INT   PATH 'CASESYSTYPE_ID',
                    WORKBASKET_ID  INT   PATH 'WORKBASKET_ID',
                    DRAFT          INT   PATH 'DRAFT'
            ) ;

	/*PARSE INPUT XML TO GET MATH TEST RESULTS*/
    SELECT  PROBLEM1,
            PROBLEM2,
            PROBLEM3
    INTO    v_PROBLEM1,
            v_PROBLEM2,
            v_PROBLEM3
    FROM    XMLTABLE('/CustomData/Attributes/Object/Item[OBJECTCODE="CDM_MATH_TEST_SAMPLE"]'
            PASSING v_CustomDataXML
            COLUMNS PROBLEM1 NUMBER PATH 'CDM_MATH_TEST_SAMPLE_PROBLEM1',
                    PROBLEM2 NUMBER PATH 'CDM_MATH_TEST_SAMPLE_PROBLEM2',
                    PROBLEM3 NUMBER PATH 'CDM_MATH_TEST_SAMPLE_PROBLEM3'
            ) ;

	/*COMPARE VALUES*/
    validationresult := NULL;
    
    IF v_PROBLEM1 <> 4 THEN
        /*-- 2+2 is Problem 1*/
        validationresult := 502;
    END IF;
    
    IF v_PROBLEM2 <> 6 THEN
        /*-- 3+3 is Problem 2*/
        validationresult := 503;
    END IF;
    
    IF v_PROBLEM3 <> 64 THEN
        /*-- 8x8 is Problem 3*/
        validationresult := 504;
    END IF;
    
    validationresult := NVL(validationresult,0) ;

EXCEPTION
WHEN OTHERS THEN
    validationresult := 501;
END;