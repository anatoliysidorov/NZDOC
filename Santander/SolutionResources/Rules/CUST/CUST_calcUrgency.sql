DECLARE
    -- INPUT
    v_CaseId INTEGER;
    v_CustomDataXML NCLOB;
    
    v_RequiredDate DATE;
    v_SubmittedDate DATE;
    v_UrgencyId INT;
    v_urgencyCode varchar2(255);
    v_FirstName nvarchar2(255);
    v_LastName nvarchar2(255);
    v_ExtPartyId INT;
    v_partytype_id INT;
    v_OrgName nvarchar2(255);
    v_OrgId INT;
    
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

    SELECT NVL(brief.col_Required_By, sysdate), NVL(brief.col_Submitted_By, sysdate), brief.COL_REQUESTER_FIRST_NAME, brief.COL_REQUESTER_LAST_NAME, cw.col_Name
    INTO v_RequiredDate, v_SubmittedDate, v_FirstName, v_LastName, v_OrgName
    FROM tbl_cdm_briefings brief
    LEFT JOIN tbl_dict_customword cw ON brief.COL_CDM_BRIEFINGORGANISATION = cw.col_Id
    WHERE brief.col_briefingsCase = v_CaseId;
    
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
    
    IF (v_FirstName IS NOT NULL AND v_LastName IS NOT NULL) THEN
        BEGIN
            SELECT col_ID INTO v_ExtPartyId  
            FROM tbl_externalparty te
            WHERE te.col_name = v_FirstName || ' '|| v_LastName;

        EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            
            SELECT col_Id into v_partytype_id 
            FROM tbl_dict_partytype 
            WHERE UPPER(col_Code) = 'REQUESTER';
            
            BEGIN
                SELECT col_ID INTO v_OrgId  
                FROM tbl_externalparty te
                WHERE te.col_name = v_OrgName;
            EXCEPTION 
                WHEN OTHERS THEN v_OrgId := null;
            END;
  
            v_ExtPartyId := f_ppl_createmodifyepfn(address      => null,
                                          customdata             => null,
                                          defaultteam_id         => null,
                                          description            => null,
                                          email                  => null,
                                          errorcode              => v_errorCode,
                                          errormessage           => v_errorMessage,
                                          externalid             => null,
                                          extsysid               => null,
                                          id                     => null,
                                          isdeleted              => 0,
                                          justcustomdata         => null,
                                          NAME                   => v_FirstName || ' ' ||v_LastName,
                                          parentexternalparty_id => v_OrgId,
                                          partytype_code         => null,
                                          partytype_id           => v_partytype_id,
                                          phone                  => null,
                                          userid                 => null,
                                          workbasket_id          => null,
                                          firstname              => v_FirstName,
                                          middlename             => null,
                                          lastname               => v_LastName,
                                          dob                    => null,
                                          prefix                 => null,
                                          suffix                 => null,
                                          partyorgtype_id        => null);
        END;
        
        UPDATE tbl_caseparty
           SET Col_Casepartyexternalparty = v_ExtPartyId
         WHERE col_casepartyCase = v_CaseId AND LOWER(col_name) = 'requester';
    END IF;
    
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