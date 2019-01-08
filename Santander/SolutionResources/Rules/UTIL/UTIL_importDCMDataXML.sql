DECLARE
    /*--INPUT*/
    v_XMLData NCLOB;
    v_ImportXmlID NUMBER;
    
    /*--INTERNAL*/
    v_result nvarchar2(250) ;
    v_res NUMBER;
    
    /*--standard*/
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255) ;
    v_successResponse NCLOB;
    v_executionlog NCLOB;
BEGIN
    v_XMLData := TRIM(:XMLdata) ;
    v_ImportXmlID := NVL(:XmlId,0) ;
    
    /*--basic pre-check*/
    IF v_XMLData IS NULL AND v_ImportXmlID = 0 THEN
        v_errorCode := 101;
        v_errorMessage := 'Data XML or XML ID can not be empty';
        GOTO cleanup;
    END IF;
    
    /*--do import*/
    v_result := f_UTIL_importDCMDataXMLfn(Input => v_XMLData,
                                          Path => NULL,
                                          TaskTemplateLevel => 1,
                                          ParentId => NULL,
                                          XmlId => v_ImportXmlID) ;
    
    /*--determine if import was succesful*/
    IF(instr(v_result,'imported') > 0) THEN
        v_res := f_DCM_createCTAccessCache;
        v_errorCode := 0;
        v_errorMessage := '';
        v_successResponse := v_result;
    ELSE
        v_errorCode := 102;
        v_errorMessage := v_result;
        v_successResponse := '';
    END IF;
    
    SELECT COL_NOTES
    INTO   v_executionlog
    FROM   tbl_ImportXML
    WHERE  col_id = v_ImportXmlID;
    
    :ExecutionLog := v_executionlog;
    
    <<cleanup>> :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    :SuccessResponse := v_successResponse;

EXCEPTION
WHEN OTHERS THEN
    :errorCode := 103;
    :errorMessage := SQLERRM;
    :SuccessResponse := '';
END;