DECLARE
    --input
    v_INPUT NVARCHAR2(32767);
    v_PATH NVARCHAR2(500) ;
    v_ignore PLS_INTEGER;
	
    --internal
    v_textResult NCLOB := EMPTY_CLOB();
    v_xml XMLTYPE;
    v_nodeExist PLS_INTEGER;
BEGIN
    --input
    v_INPUT := TRIM(:INPUT) ;
    v_PATH := TRIM(:PATH) ;
    
    --check if empty string and that node exists
    IF(v_INPUT IS NULL OR v_PATH IS NULL) THEN
        RETURN NULL;
    END IF;
    
    v_xml := XMLTYPE(v_INPUT);    
	
    SELECT existsNode(v_xml,TO_CHAR(v_PATH))
    INTO v_nodeExist
    FROM dual;
    
    IF v_nodeExist = 0 THEN
        NULL;
    END IF;
    
    --get node
    v_textResult := v_xml.extract(v_PATH).getClobval();
    
    --return string
    RETURN v_textResult;
EXCEPTION
WHEN OTHERS THEN
    RETURN NULL;
END;