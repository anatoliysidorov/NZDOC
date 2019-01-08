DECLARE 
    v_id INTEGER;
    v_name NVARCHAR2(255);
    v_partyTypeName NVARCHAR2(255);
    v_pageCode NVARCHAR2(255);
    v_pageParams NCLOB;
    v_customData NCLOB; 
    v_TARGET_RAWTYPE   NVARCHAR2(255);
    v_TARGET_ELEMENTID NVARCHAR2(255);
    
BEGIN
    
    v_id := :ID;

    BEGIN
        SELECT 
            ep.col_name, tdp.col_name INTO 
            v_name, v_partyTypeName
        FROM tbl_externalparty ep  
        LEFT JOIN tbl_dict_partytype tdp ON tdp.col_id = ep.col_externalpartypartytype
        WHERE ep.col_Id = v_id;  
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
    END;
       
    BEGIN 
        SELECT ap.TARGET_RAWTYPE, ap.TARGET_ELEMENTID
          INTO v_TARGET_RAWTYPE, v_TARGET_ELEMENTID
       FROM vw_dcm_assocpage ap
       INNER JOIN tbl_dict_PartyType pt ON ap.PARTYTYPE = pt.col_id
       INNER JOIN tbl_ExternalParty ep ON pt.col_id = ep.COL_EXTERNALPARTYPARTYTYPE
       WHERE ep.col_id = v_id
             AND lower(ap.PAGETYPE_CODE) = lower('FULL_PAGE_PARTY_DETAIL');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
    END;   
     
    IF v_TARGET_RAWTYPE IS NULL OR v_TARGET_ELEMENTID IS NULL THEN
        BEGIN
          SELECT col_id
            INTO v_TARGET_ELEMENTID
            FROM tbl_FOM_PAGE
           WHERE lower(col_usedfor) = 'extparty'
             AND col_systemdefault = 1 AND ROWNUM = 1;
           v_TARGET_RAWTYPE := 'PAGE';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            NULL;
        END;    
    END IF;
    
    IF v_TARGET_RAWTYPE IS NOT NULL AND v_TARGET_ELEMENTID IS NOT NULL THEN
        IF upper(v_TARGET_RAWTYPE) = 'PAGE' THEN
          v_pageCode := 'root_UTIL_CaseManagement';
          v_pageParams := '<PageParams>' ||
                            '<ExtParty_Id>' || v_id || '</ExtParty_Id>' ||
                            '<app>ExternalPartyDetailRuntime</app>' ||
                            '<group>FOM</group>' ||
                            '<usePageConfig>1</usePageConfig>' ||
                        '</PageParams>';
        ELSE
          v_pageCode := v_TARGET_ELEMENTID;
          v_pageParams := '<PageParams>' ||
                            '<ExtParty_Id>' || v_id || '</ExtParty_Id>' ||
                        '</PageParams>';
        END IF;
    END IF;  
    v_customData := f_PPL_getPartyCustomData(v_id);
    
    -- Output
    :Name := v_name;
    :PartyType_Name := v_partyTypeName;
    :PageCode := v_pageCode;
    :PageParams := v_pageParams;
    :CustomData := v_customData; 
END;