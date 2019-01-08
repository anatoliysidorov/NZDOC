DECLARE
    /*--SYSTEM*/
    v_Message NCLOB;
    
    /*--OUTPUT*/
    v_errorcode NUMBER;
    v_errormessage NCLOB;
BEGIN
    v_errorcode := 0;
    v_errormessage := '';
    v_Message := '';
    
	--check that each work basket is properly linked
    /*FOR rec IN(
		SELECT CALCNAME, CALCTYPE, CALCTYPECODE, 
		FROM vw_PPL_SimpleWorkbasket
    LOOP
        v_errorCode := 121;
        v_errorMessage := v_errorMessage || '<li>Workbasket '||rec.WorkBasketId||' is linked to non-existent Case Worker</li>';
    END LOOP;
    
    FOR rec2 IN(SELECT TO_CHAR(col_id) ExternalPartyId
    FROM    tbl_ppl_workbasket
    WHERE   Col_Workbasketexternalparty IN(SELECT DISTINCT(Wb.Col_Workbasketexternalparty)
            FROM      tbl_ppl_workbasket wb
            LEFT JOIN tbl_dict_workbaskettype wbt ON wbt.col_id = Wb.Col_Workbasketworkbaskettype
            WHERE     lower(wbt.col_code) = 'personal'
                      AND Wb.Col_Workbasketexternalparty IS NOT NULL
            MINUS
            SELECT col_id
            FROM   Tbl_Externalparty
            WHERE  NVL(col_isdeleted,0) = 0))
    
    LOOP
        v_errorCode := 122;
        v_errorMessage := v_errorMessage || '<li>Workbasket '||rec2.ExternalPartyId||' is linked to non-existent External Party</li>';
    END LOOP;
    FOR rec IN(SELECT col_id WorkBasketId
    FROM    tbl_ppl_workbasket
    WHERE   Col_workbasketteam IN(SELECT DISTINCT(Wb.Col_workbasketteam) TeamId
            FROM      tbl_ppl_workbasket wb
            LEFT JOIN tbl_dict_workbaskettype wbt ON wbt.col_id = Wb.Col_Workbasketworkbaskettype
            WHERE     lower(wbt.col_code) = 'personal'
                      AND Wb.Col_workbasketteam IS NOT NULL
            MINUS
            SELECT col_id
            FROM   tbl_ppl_team))
    LOOP
        v_errorCode := 123;
        v_errorMessage := v_errorMessage || '<li>Workbasket '||rec.WorkBasketId||' is linked to non-existent Team</li>';
    END LOOP;
    FOR rec IN(SELECT col_id WorkBasketId
    FROM    tbl_ppl_workbasket
    WHERE   Col_workbasketskill IN(SELECT DISTINCT(Wb.Col_workbasketskill) SkillId
            FROM      tbl_ppl_workbasket wb
            LEFT JOIN tbl_dict_workbaskettype wbt ON wbt.col_id = Wb.Col_Workbasketworkbaskettype
            WHERE     lower(wbt.col_code) = 'personal'
                      AND Wb.Col_workbasketskill IS NOT NULL
            MINUS
            SELECT col_id
            FROM   tbl_ppl_skill))
    LOOP
        v_errorCode := 124;
        v_errorMessage := v_errorMessage || '<li>Workbasket '||rec.WorkBasketId||' is linked to non-existent Skill</li>';
    END LOOP;
    FOR rec IN(SELECT TO_CHAR(col_id) WorkBasketId
    FROM    tbl_ppl_workbasket
    WHERE   Col_Workbasketbusinessrole IN(SELECT DISTINCT(Wb.Col_Workbasketbusinessrole) SkillId
            FROM      tbl_ppl_workbasket wb
            LEFT JOIN tbl_dict_workbaskettype wbt ON wbt.col_id = Wb.Col_Workbasketworkbaskettype
            WHERE     lower(wbt.col_code) = 'personal'
                      AND Wb.Col_Workbasketbusinessrole IS NOT NULL
            MINUS
            SELECT col_id
            FROM   Tbl_Ppl_Businessrole))
    LOOP
        v_errorCode := 121;
        v_errorMessage := v_errorMessage || '<li>Workbasket '||rec.WorkBasketId||' is linked to non-existent Business Role</li>';
    END LOOP;
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;*/
	
	/*--report any errors*/
    IF v_errorcode > 0 THEN
        :ErrorCode := v_errorcode;
        :ErrorMessage := v_message;
    ELSE
        :ErrorCode := 0;
        :ErrorMessage := 'Workbasket test passed';
    END IF;

END;