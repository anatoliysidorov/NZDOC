DECLARE
    l_template NVARCHAR2(32767);
BEGIN
	--BASIC CHECKS
    IF :p_template IS NULL THEN
        RETURN NULL;
    END IF;
	
	IF :p_placeholders IS NULL THEN
		RETURN :p_template;
	END IF;
	
	--LOOP THROUGH PLACEOLDERS AND REPLACE THEM IN TEMPLATE
    l_template := :p_template;
	
    FOR pRec IN(SELECT fullLine,
            REGEXP_SUBSTR(fullLine,'[^' || :p_delim2 || ']+',1,1) as pCode,
            NVL(REGEXP_SUBSTR(fullLine,'[^' || :p_delim2 || ']+$'),0) as pValue
    FROM   (SELECT trim(regexp_substr(p_placeholders,'[^' ||:p_delim || ']+',1,LEVEL)) fullLine
            FROM    dual
                    CONNECT BY LEVEL <= regexp_count(p_placeholders,:p_delim) +1))
    LOOP
        l_template := REGEXP_REPLACE(l_template,'@' ||pRec.pCode ||'@+',pRec.pValue,1,0,'i');
    END LOOP;
	
	--RETURN GENERATED MESSAGE
    RETURN l_template;
END;