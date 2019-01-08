DECLARE 
    v_casetype_id          NUMBER; 
    v_output               NCLOB; 
    v_res                  NUMBER; 
    v_errorcode            NUMBER; 
    v_errormessage         NCLOB; 
    v_successmessage       NCLOB; 
    v_casetype_name        NVARCHAR2(255); 
    v_casetype_code        NVARCHAR2(255); 
    v_casetype_description NVARCHAR2(255); 
    v_procedure_id         NVARCHAR2(255); 
    v_procedure_code       NVARCHAR2(255); 
BEGIN 
    v_casetype_id := :CaseType_Id; 
    v_output := '<CaseType></CaseType>'; 
    v_errorcode := 0; 
    v_errormessage := ''; 
    v_successmessage := 'Case Type: '; 
    v_casetype_name := ''; 
    v_casetype_code := ''; 
    :ErrorCode := 0; 
    :ErrorMessage := ''; 
    :SuccessMessage := ''; 
    :CaseTypeXML := v_output; 
    IF v_casetype_id IS NULL THEN 
      v_errorcode := 121; 
      v_errormessage := 'Case Type Id can not be NULL'; 
      GOTO cleanup; 
    END IF; 

    BEGIN 
        SELECT cst.col_name, 
               cst.col_code 
        INTO   v_casetype_name, v_casetype_code 
        FROM   tbl_dict_casesystype cst 
        WHERE  cst.col_id = v_casetype_id; 
    EXCEPTION 
        WHEN no_data_found THEN 
          v_errorcode := 1; 
          v_errormessage := 'Case Type with the following id: ' ||v_casetype_id || ' was not found!'; 
          GOTO cleanup; 
    END; 

    v_output := F_util_create_xml_case_type (casetype => v_casetype_code, is_dict_load => 1);
    IF ( v_output <> Empty_clob() ) THEN 
      v_successmessage := v_successmessage || v_casetype_name ||' was successfully exported'; 
    END IF; 

    --dbms_output.put_line(v_successMessage); 
    --dbms_output.put_line(v_output); 
    :SuccessMessage := v_successmessage; 
    :CaseTypeXML := v_output; 

    <<cleanup>> 
    :ErrorCode := v_errorcode; 
    :ErrorMessage := v_errormessage; 
    dbms_output.Put_line(v_errormessage); 
    dbms_output.Put_line(v_successmessage); 
END; 