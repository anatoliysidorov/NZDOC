DECLARE
    -- INPUT
    v_CaseId INTEGER;
    v_CustomDataXML NCLOB;
    
    v_RequiredDate DATE;
    v_SubmittedDate DATE;
    v_UrgencyId INT;
    v_urgencyCode varchar2(255);
    
    -- OUTPUT
    v_ErrorCode         NUMBER;
    v_ErrorMessage      NCLOB;
    v_validationresult  NUMBER; 
BEGIN
    v_CustomDataXML := :Input;
    v_CaseId := to_number(f_UTIL_extractXmlAsTextFn(INPUT=> v_CustomDataXML, PATH=>'/CustomData/Attributes/CaseId/text()'));
    
    v_ErrorCode        := 0; 
    v_ErrorMessage     := NULL; 
    v_validationresult := 1; --valid by default

    SELECT NVL(col_Required_By, sysdate), NVL(col_Submitted_By, sysdate)
    INTO v_RequiredDate, v_SubmittedDate
    FROM tbl_cdm_briefings
    WHERE col_briefingsCase = v_CaseId;
    
    IF TRUNC(v_RequiredDate - v_SubmittedDate) < 3 THEN 
        v_urgencyCode := 'HIGH_URGENCY';
    ELSE 
        v_urgencyCode := 'STANDARD';
    END IF;
    
    BEGIN
        SELECT cw.col_Id
        INTO v_UrgencyId
        FROM tbl_dict_customcategory cc 
        JOIN tbl_dict_customword cw ON cw.col_wordcategory = cc.col_id AND UPPER(cc.col_code) = 'URGENCY'
        WHERE cw.col_code = v_urgencyCode;
        
        UPDATE tbl_cdm_briefings 
        SET col_cdm_briefingsUrgency = v_UrgencyId
        WHERE col_briefingsCase = v_CaseId;
    EXCEPTION 
        WHEN OTHERS THEN NULL;
    END;
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    :validationResult := v_validationresult;
    
    /*
    INSERT INTO tbl_log (
        col_bigdata1, col_data1, col_data10, col_data11
    ) VALUES (
        v_CustomDataXML, TRUNC(v_RequiredDate - v_SubmittedDate), v_UrgencyId, v_CaseId
    );
    */
END;