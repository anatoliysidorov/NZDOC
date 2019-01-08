DECLARE
    /*--SYSTEM*/
    v_oneTable NVARCHAR2(50);
    v_manyTable NVARCHAR2(50);
    v_statement VARCHAR2(2000);
    v_count INT;
    v_StatementLog NCLOB;
    v_Message NCLOB;

    /*--OUTPUT*/
    v_errorcode NUMBER;
    v_errormessage NCLOB;
BEGIN
    v_errorcode := 0;
    v_errormessage := '';
    v_StatementLog := '';
    v_Message := '';

    /*--check if all data model is consistent*/
    FOR REC IN(SELECT    p.SOURCEOBJECTID AS SOURCEOBJECTID,
               p.TARGETOBJECTID AS TARGETOBJECTID,
               p.SOURCECARDINALITYTYPE AS SOURCECARDINALITYTYPE,
               /*-- 1 = one, 2 = many*/
               p.TARGETCARDINALITYTYPE AS TARGETCARDINALITYTYPE,
               /*-- 1 = one, 2 = many*/
               p.localcode AS RELATION_CODE,
               p.name AS name,
               bSource.localcode AS SOURCE_CODE,
               bTarget.localcode AS TARGET_CODE
    FROM       @TOKEN_SYSTEMDOMAINUSER@.conf_environment e
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version v        ON v.versionid = e.depversionid
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_BORelation p     ON p.componentid = v.componentid
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bSource ON bSource.OBJECTID = p.SOURCEOBJECTID AND bSource.componentid = v.componentid
    INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bTarget ON bTarget.OBJECTID = p.TARGETOBJECTID AND bTarget.componentid = v.componentid
    WHERE      e.code = '@TOKEN_DOMAIN@'
               AND UPPER(bSource.localcode) NOT LIKE 'CDM%'
               AND UPPER(bSource.localcode) NOT LIKE '%CC'
               AND UPPER(bTarget.localcode) NOT LIKE 'CDM%'
               AND UPPER(bTarget.localcode) NOT LIKE '%CC')
    LOOP
        /*--get the correct one-to-many order*/
        v_oneTable := '';
        v_manyTable := '';
        IF rec.SOURCECARDINALITYTYPE = 1 THEN
            v_oneTable := rec.SOURCE_CODE;
            v_manyTable := rec.TARGET_CODE;
        ELSE
            v_manyTable := rec.SOURCE_CODE;
            v_oneTable := rec.TARGET_CODE;
        END IF;

        /*--make statement*/
        v_statement := 'SELECT count(1) FROM ' || 'tbl_' || v_manyTable || ' tableMany';
        v_statement := v_statement || ' ' || 'LEFT JOIN tbl_' || v_oneTable || ' tableOne ON tableOne.col_id = tableMany.col_' || rec.RELATION_CODE;
        v_statement := v_statement || ' ' || 'WHERE tableMany.col_' || rec.RELATION_CODE || ' > 0 AND ' || 'tableOne.col_id IS NULL';

        /*--execute the statement and write message if there are broken references*/
        BEGIN
            EXECUTE IMMEDIATE v_statement INTO v_count;
			
            IF v_count > 0 THEN
                v_errorcode := 101;
                v_message := v_message || f_UTIL_wrapTextInNode(NodeTag => 'li',
                                                                msg => 'ONE ' || v_oneTable || ' TO MANY ' || v_manyTable || ' ON col_' || rec.RELATION_CODE || ' - issues ' || TO_CHAR(v_count));
                v_StatementLog := v_StatementLog || f_UTIL_wrapTextInNode(NodeTag => 'li',
                                                                          msg => REPLACE(v_statement,'count(1)','tableMany.*'));
            END IF;
        EXCEPTION
        WHEN OTHERS THEN
            :ErrorCode := 101;
			:ErrorMessage := DBMS_UTILITY.FORMAT_ERROR_STACK;
        END;
    END LOOP;

	/*--check if any business objects are set as auditable*/
	FOR REC IN(SELECT
			   bo.NAME AS BADisplayName
	FROM       @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs     ON bo.componentid = vrs.componentid
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env ON vrs.versionid = env.depversionid
	WHERE      env.code = '@TOKEN_DOMAIN@' and bo.AUDITABLE = 1)
	LOOP
		 v_message := v_message || f_UTIL_wrapTextInNode(NodeTag => 'li',
						msg => 'Business Object ' || rec.BADisplayName || ' is auditable');
	END LOOP;
	
	/*--check if any business objects attributes are set as auditable*/
	FOR REC IN( SELECT     bo.NAME || ' | '  || ba.columntitle  AS BADisplayName
	FROM       @TOKEN_SYSTEMDOMAINUSER@.conf_boattribute ba
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_type tp         ON ba.attributetypeid = tp.typeid
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_boobject bo     ON ba.objectid = bo.objectid
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_version vrs     ON bo.componentid = vrs.componentid
	INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.conf_environment env ON vrs.versionid = env.depversionid
	WHERE      env.code = '@TOKEN_DOMAIN@'  and ba.AUDITABLE = 1)
	LOOP
		 v_message := v_message || f_UTIL_wrapTextInNode(NodeTag => 'li',
						msg => 'Business Object Attribute ' || rec.BADisplayName || ' is auditable');
	END LOOP;
	

    /*--DBMS_OUTPUT.PUT_LINE(v_StatementLog) ;*/
    IF v_errorcode > 0 THEN
        :ErrorCode := v_errorcode;
        :ErrorMessage := v_message || '<br>==STATEMENT LOGS==<br>' || v_StatementLog;
    ELSE
        :ErrorCode := 0;
        :ErrorMessage := 'Data integrity and audit test passed' || v_StatementLog;
    END IF;
END;