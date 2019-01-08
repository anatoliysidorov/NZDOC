DECLARE
    v_objecttype NVARCHAR2(255);
    v_objectid INTEGER;
    v_listtype NVARCHAR2(255);
    v_listids NVARCHAR2(4000);
    v_count INTEGER;
    v_errorcode     NUMBER;
    v_errormessage  NVARCHAR2(255);
BEGIN
    BEGIN
    v_errormessage := '';
    v_errorcode := 0;
    
    v_objecttype := UPPER(:ObjectType);
    v_objectid := :ObjectId;
    v_listtype := UPPER(:ListType);
    v_listids := :ListIds;
    
    IF (v_objecttype = '' OR v_objecttype IS NULL) THEN
        v_errormessage := 'ObjectType could not be empty'; 
        v_errorcode := 1;
        GOTO cleanup;
    END IF;
    
    IF (v_objectid = '' OR v_objectid IS NULL) THEN
        v_errormessage := 'ObjectId could not be empty'; 
        v_errorcode := 2;
        GOTO cleanup;
    END IF;
    
    IF (v_listtype = '' OR v_listtype IS NULL) THEN
        v_errormessage := 'ListType could not be empty'; 
        v_errorcode := 3;
        GOTO cleanup;
    END IF;
    
    IF (v_listids = '' OR v_listids IS NULL) THEN
        v_errormessage := 'ListIds could not be empty'; 
        v_errorcode := 4;
        GOTO cleanup;
    END IF;
    
    CASE v_listtype
        WHEN 'TEAMS' THEN BEGIN
            IF v_objecttype = 'WORKBASKET' THEN 
                FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                LOOP
                    SELECT COUNT(*) INTO v_count FROM TBL_MAP_WORKBASKETTEAM WHERE COL_MAP_WB_TM_TEAM = rec.id AND COL_MAP_WB_TM_WORKBASKET = v_objectid;
                    IF v_count = 0 THEN
                        INSERT INTO TBL_MAP_WORKBASKETTEAM (
                          COL_MAP_WB_TM_TEAM,
                          COL_MAP_WB_TM_WORKBASKET
                        ) VALUES (
                          rec.id,
                          v_objectid
                        );
                    END IF;
                END LOOP;
            END IF;
        END;
        WHEN 'BUSINESSROLES' THEN BEGIN
            IF v_objecttype = 'WORKBASKET' THEN
                FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                LOOP
                    SELECT COUNT(*) INTO v_count FROM TBL_MAP_WORKBASKETBUSNESSROLE WHERE COL_MAP_WB_WR_BUSINESSROLE = rec.id AND COL_MAP_WB_BR_WORKBASKET = v_objectid;
                    IF v_count = 0 THEN
                        INSERT INTO TBL_MAP_WORKBASKETBUSNESSROLE (
                          COL_MAP_WB_WR_BUSINESSROLE,
                          COL_MAP_WB_BR_WORKBASKET
                        ) VALUES (
                          rec.id,
                          v_objectid
                        );
                    END IF;
                END LOOP;
            END IF;
        END;
        WHEN 'CASEWORKERS' THEN BEGIN
            CASE v_objecttype
                WHEN 'TEAM' THEN BEGIN
                    FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                    LOOP
                        SELECT COUNT(*) INTO v_count FROM TBL_CASEWORKERTEAM WHERE COL_TM_PPL_CASEWORKER = rec.id AND COL_TBL_PPL_TEAM = v_objectid;
                    	IF v_count = 0 THEN
                            INSERT INTO TBL_CASEWORKERTEAM (
                              COL_Tm_PPL_CASEWORKER,
                              COL_TBL_PPL_TEAM
                            ) VALUES (
                              rec.id,
                              v_objectid
                            );
                        END IF;
                    END LOOP;
                END;
                WHEN 'BUSINESSROLE' THEN BEGIN
                    FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                    LOOP
                        SELECT COUNT(*) INTO v_count FROM TBL_CASEWORKERBUSINESSROLE WHERE COL_BR_PPL_CASEWORKER = rec.id AND COL_TBL_PPL_BUSINESSROLE = v_objectid;
                    	IF v_count = 0 THEN
                            INSERT INTO TBL_CASEWORKERBUSINESSROLE (
                              COL_br_PPL_CASEWORKER,
                              COL_TBL_PPL_BUSINESSROLE
                            ) VALUES (
                              rec.id,
                              v_objectid
                            );
                        END IF;
                    END LOOP;
                END;
                WHEN 'SKILL' THEN BEGIN
                    FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                    LOOP
                    	SELECT COUNT(*) INTO v_count FROM TBL_CASEWORKERSKILL WHERE COL_SK_PPL_CASEWORKER = rec.id AND COL_TBL_PPL_SKILL = v_objectid;
                    	IF v_count = 0 THEN
                            INSERT INTO TBL_CASEWORKERSKILL (
                              COL_sk_PPL_CASEWORKER,
                              COL_TBL_PPL_SKILL
                            ) VALUES (
                              rec.id,
                              v_objectid
                            );
                        END IF;
                    END LOOP;
                END;
                WHEN 'WORKBASKET' THEN BEGIN
                    FOR rec IN (SELECT TO_NUMBER(column_value) AS id FROM TABLE(@TOKEN_SYSTEMDOMAINUSER@.ASF_SPLIT(v_listids, ',')))
                    LOOP
                        SELECT COUNT(*) INTO v_count FROM TBL_MAP_WORKBASKETCASEWORKER WHERE COL_MAP_WB_CW_CASEWORKER = rec.id AND COL_MAP_WB_CW_WORKBASKET = v_objectid;
                    	IF v_count = 0 THEN
                            INSERT INTO TBL_MAP_WORKBASKETCASEWORKER (
                              COL_MAP_WB_CW_CASEWORKER,
                              COL_MAP_WB_CW_WORKBASKET
                            ) VALUES (
                              rec.id,
                              v_objectid
                            );
                        END IF;
                    END LOOP;
                END;
                ELSE
                    v_errormessage := 'Unknown object type'; 
                    v_errorcode := 5;
            END CASE;
        END;
         ELSE
            v_errormessage := 'Unknown list type'; 
            v_errorcode := 6;
    END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            v_errormessage := SQLERRM;
            v_errorcode := SQLCODE; 
    END; 
    <<cleanup>>
    :errorMessage := v_errormessage;
    :errorCode := v_errorcode; 
END;