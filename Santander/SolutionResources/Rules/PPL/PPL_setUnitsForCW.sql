DECLARE
	v_CaseworkerId  NUMBER;
	v_ObjectType	  VARCHAR2(255);
	v_MembersList	  VARCHAR2(2000);
BEGIN

	v_CaseworkerId:= :CASEWORKERID;
	v_ObjectType  := UPPER(:OBJECTTYPE);
	v_MembersList := :MEMBERIDS;

	--TEAM
	IF (v_ObjectType = 'TEAM') THEN
		--add
		FOR rec IN (
        Select 
            cw_u.col_tm_ppl_caseworker as cw_id,
            t.col_id                    as unit_id
        FROM tbl_ppl_team t
            LEFT JOIN tbl_caseworkerteam cw_u ON (t.col_id = cw_u.col_tbl_ppl_team AND cw_u.col_tm_ppl_caseworker = v_CaseworkerId)
        Where t.col_id IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')))
    )
		LOOP
        If rec.cw_id is null Then
            INSERT INTO TBL_CASEWORKERTEAM (COL_TM_PPL_CASEWORKER, COL_TBL_PPL_TEAM)
            VALUES (v_CaseworkerId, rec.unit_id);
        End If;
		END LOOP;

		--delete
    DELETE FROM TBL_CASEWORKERTEAM relay
    WHERE relay.col_tm_ppl_caseworker = v_CaseworkerId
      AND relay.COL_TBL_PPL_TEAM NOT IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')));
	END IF;

	--SKILL
	IF (v_ObjectType = 'SKILL') THEN
		--add
		FOR rec IN (
        Select 
            cw_u.col_sk_ppl_caseworker as cw_id,
            t.col_id                    as unit_id
        FROM TBL_PPL_SKILL t
            LEFT JOIN TBL_CASEWORKERSKILL cw_u ON (t.col_id = cw_u.COL_TBL_PPL_SKILL AND cw_u.col_sk_ppl_caseworker = v_CaseworkerId)
        Where t.col_id IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')))
    )
		LOOP
        If rec.cw_id is null Then
            INSERT INTO TBL_CASEWORKERSKILL (col_sk_ppl_caseworker, COL_TBL_PPL_SKILL)
            VALUES (v_CaseworkerId, rec.unit_id);
        End If;
		END LOOP;

		--delete
    DELETE FROM TBL_CASEWORKERSKILL relay
    WHERE relay.col_sk_ppl_caseworker = v_CaseworkerId
      AND relay.COL_TBL_PPL_SKILL NOT IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')));
	END IF;

	--BUSINESSROLE
	IF (v_ObjectType = 'BUSINESSROLE') THEN
		--add
		FOR rec IN (
        Select 
            cw_u.COL_BR_PPL_CASEWORKER as cw_id,
            t.col_id                    as unit_id
        FROM TBL_PPL_BUSINESSROLE t
            LEFT JOIN TBL_CASEWORKERBUSINESSROLE cw_u ON (t.col_id = cw_u.COL_tbl_PPL_BUSINESSROLE AND cw_u.col_br_ppl_caseworker =v_CaseworkerId)
        
        Where t.col_id IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')))
    )
		LOOP
        If rec.cw_id is null Then
            INSERT INTO TBL_CASEWORKERBUSINESSROLE (COL_br_PPL_CASEWORKER, COL_TBL_PPL_BUSINESSROLE)
            VALUES (v_CaseworkerId, rec.unit_id);
        End If;
		END LOOP;

		--delete
    DELETE FROM TBL_CASEWORKERBUSINESSROLE relay
    WHERE relay.col_br_ppl_caseworker = v_CaseworkerId
      AND relay.COL_TBL_PPL_BUSINESSROLE NOT IN (SELECT TO_NUMBER(column_value) FROM TABLE (ASF_SPLIT(v_MembersList, '|||')));
	END IF;
END;