--Sample of Validation Rule for Common Event
--Rule Type - SQL Non Query
--Deploy as Function - Yes

--Input:
--  Input, IN nclob  (collection of passed parameters in XML format)
--Output
--  ValidationResult, Integer (0 = don't allow, 1 = allow)
--  ErrorCode, Integer
--  ErrorMessage, Text Area

DECLARE
    --INPUT
    v_input NCLOB;
	
    --INTERNAL
    v_CaseTypeID INT;
	v_EmailAddress NVARCHAR2(255);
BEGIN
    --Input--
    v_input := :INPUT;
	
    --GET DATA FROM XML
    v_CaseTypeID := TO_NUMBER(f_UTIL_extractXmlAsTextFn(INPUT=> v_input,
                                           PATH=>'/CustomData/Attributes/Object[@ObjectCode="CASE"]/Item/CASESYSTYPE_ID/text()'));
    
	v_EmailAddress := f_UTIL_extractXmlAsTextFn(INPUT=> v_input,
                                           PATH=>'/CustomData/Attributes/Form[@name="SIMPLE_NON_MDM_TEST"]/EMAIL/text()');
	--DO SOME VALIDATION
	IF v_EmailAddress IS NULL THEN
		:ValidationResult := 0;
		:ErrorMessage := 'The email address can not be empty';
		:ErrorCode := 301;
	ELSIF v_CaseTypeID >10 THEN
		:ValidationResult := 0;
		:ErrorMessage := 'The Case Type should have an ID less than 10';
		:ErrorCode := 302;
	ELSE
		:ValidationResult := 1;
        :ErrorMessage := NULL;
        :ErrorCode := NULL;
	END IF;	
END;