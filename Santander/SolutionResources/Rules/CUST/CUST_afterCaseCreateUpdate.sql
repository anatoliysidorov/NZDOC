DECLARE
    v_CaseId INTEGER;
    v_CustomDataXML XMLTYPE;
    v_RequiredDate DATE;
    v_SubmittedDate DATE;
    v_UrgencyId INT;
    v_urgencyCode varchar2(255);
BEGIN
    v_CustomDataXML := XMLType(:Input);
    v_CaseId := :CaseId;

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
    :CaseExtId := 0;
    /*INSERT INTO tbl_log (
        col_bigdata1
    ) VALUES (
        :Input
    );*/
END;