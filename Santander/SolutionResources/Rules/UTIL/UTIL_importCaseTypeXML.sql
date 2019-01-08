DECLARE
v_input nclob;
v_errorCode number;
v_errorMessage nclob;
v_successMessage nclob;
v_result nvarchar2(2500);
v_res number;
v_colidxml number;
BEGIN
v_result :='';
v_input := :CaseTypeXML;
v_colidxml := :XML_ID;
v_errorCode := 0;
v_errorMessage := '';
v_successMessage := '';
:ErrorCode := 0;
:ErrorMessage := '';
:SuccessMessage := '';

v_res := 1; 
IF V_input IS NULL and v_colidxml is null THEN
  v_errorCode := 121;
  v_errorMessage := 'Case Type XML or XML ID can not be empty';
  goto cleanup;
END IF;
v_result := f_UTIL_extract_case_type(Input => v_input, Path => null, TaskTemplateLevel => 1, ParentId => null, XmlId => v_colidxml);
--v_res := TEST_SLEEP(SleepSeconds => 125);
v_successMessage := 'Case Type was successfully imported';
if(v_result = 'Ok') THEN
--if(v_res = 1) THEN
	:SuccessMessage := v_successMessage;
 ELSE
     v_errorCode := 121;
     v_errorMessage := v_result;
 END IF;
<<cleanup>>
:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;
dbms_output.put_line(v_errorMessage);
dbms_output.put_line(v_successMessage);
END;